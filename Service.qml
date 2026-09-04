import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  property real speed: 0.0
  property bool stateLoaded: false
  property bool deviceAvailable: true
  property string errorMessage: ""
  property bool pendingApply: false
  property bool pendingSet: false
  property real pendingSpeed: 0.0

  readonly property string helperPath: decodeURIComponent(
    Qt.resolvedUrl("scripts/trackpad-speed").toString().replace(/^file:\/\//, ""))
  readonly property string appInstallerPath: decodeURIComponent(
    Qt.resolvedUrl("scripts/install-app-entry").toString().replace(/^file:\/\//, ""))

  signal speedChangedByUser(real value)

  function clamped(value) {
    return Math.max(-1, Math.min(1, Math.round(Number(value) * 20) / 20))
  }

  function refresh() {
    if (!readProcess.running) readProcess.running = true
  }

  function setSpeed(value) {
    root.speed = clamped(value)
    root.stateLoaded = true
    root.errorMessage = ""
    root.speedChangedByUser(root.speed)
    applyDelay.restart()
  }

  function applySavedSpeed() {
    if (applyProcess.running) {
      pendingApply = true
      return
    }
    applyProcess.command = ["bash", helperPath, "apply"]
    applyProcess.running = true
  }

  Component.onCompleted: {
    installAppProcess.running = true
    refresh()
  }

  Timer {
    id: applyDelay
    interval: 100
    repeat: false
    onTriggered: {
      if (applyProcess.running) {
        root.pendingSet = true
        root.pendingSpeed = root.speed
        return
      }
      applyProcess.command = ["bash", root.helperPath, "set", root.speed.toFixed(2)]
      applyProcess.running = true
    }
  }

  Process {
    id: readProcess
    command: ["bash", root.helperPath, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = Number(String(text || "").trim())
        if (!isNaN(value)) root.speed = root.clamped(value)
        root.stateLoaded = true
        root.applySavedSpeed()
      }
    }
  }

  Process {
    id: applyProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = Number(String(text || "").trim())
        if (!isNaN(value)) root.speed = root.clamped(value)
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.errorMessage = String(text || "").trim()
    }
    onExited: function(exitCode) {
      root.deviceAvailable = exitCode === 0
      if (root.pendingSet) {
        root.pendingSet = false
        applyProcess.command = ["bash", root.helperPath, "set", root.pendingSpeed.toFixed(2)]
        applyProcess.running = true
        return
      }
      if (root.pendingApply) {
        root.pendingApply = false
        root.applySavedSpeed()
      }
    }
  }

  Process {
    id: installAppProcess
    command: ["bash", root.appInstallerPath]
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !root.stateLoaded) return
      var name = String(event.name || "")
      if (name === "configreloaded" || name === "monitoradded") reapplyTimer.restart()
    }
  }

  Timer {
    id: reapplyTimer
    interval: 250
    repeat: false
    onTriggered: root.applySavedSpeed()
  }
}
