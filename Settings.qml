import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Ui
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false
  property real displayedSpeed: service && service.stateLoaded ? service.speed : 0.0
  property int selectedPreset: nearestPreset(displayedSpeed)
  readonly property var presets: [
    { name: "Precise", value: -0.40 },
    { name: "Natural", value: 0.00 },
    { name: "Fast", value: 0.60 },
    { name: "Swift", value: 1.00 }
  ]

  readonly property QtObject palette: QtObject {
    property color foreground: Color.popups.text
    property color background: Color.popups.background
  }

  function open(payloadJson) {
    opened = true
    if (service) {
      service.refresh()
      service.refreshBarVisibility()
    }
  }

  function close() { opened = false }

  function clamped(value) {
    return Math.max(-1, Math.min(1, Math.round(Number(value) * 20) / 20))
  }

  function signed(value) {
    var rounded = clamped(value)
    return (rounded > 0 ? "+" : "") + rounded.toFixed(2)
  }

  function mood(value) {
    if (value <= -0.65) return "VERY PRECISE"
    if (value <= -0.20) return "PRECISE"
    if (value < 0.20) return "NATURAL"
    if (value < 0.75) return "FAST"
    return "SWIFT"
  }

  function nearestPreset(value) {
    var best = 0
    var distance = 999
    for (var i = 0; i < presets.length; i++) {
      var candidate = Math.abs(presets[i].value - value)
      if (candidate < distance) {
        best = i
        distance = candidate
      }
    }
    return best
  }

  function preview(value) {
    displayedSpeed = clamped(value)
    selectedPreset = nearestPreset(displayedSpeed)
  }

  function commit(value) {
    preview(value)
    if (service) service.setSpeed(displayedSpeed)
    if (shell) {
      shell.summon("omarchy.osd", JSON.stringify({
        icon: "touchpad",
        value: Math.round((displayedSpeed + 1) * 50)
      }))
    }
  }

  Connections {
    target: root.service
    function onSpeedChanged() { root.preview(root.service.speed) }
  }

  PanelWindow {
    id: window
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-trackpad-speed"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    BorderSurface {
      id: card
      width: Math.min(Style.space(420), window.width - Style.gapsOut * 2)
      height: content.implicitHeight + Style.spacing.panelPadding * 2
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        focus: true
        Keys.onEscapePressed: root.close()

        Column {
          id: content
          width: parent.width
          spacing: Style.space(14)

          Item {
            width: parent.width
            implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

            Text {
              id: heroIcon
              text: "󰟸"
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              id: heroLabels
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(14)
              anchors.right: closeButton.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                text: "Trackpad speed"
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: root.service && !root.service.deviceAvailable
                  ? "NO TRACKPAD DETECTED" : root.mood(root.displayedSpeed)
                color: root.service && !root.service.deviceAvailable
                  ? Color.urgent : Qt.darker(Color.popups.text, 1.4)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
              }
            }

            Button {
              id: closeButton
              text: "Done"
              foreground: Color.popups.text
              fontFamily: Style.font.family
              bordered: true
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              onClicked: root.close()
            }
          }

          PanelSeparator { foreground: Color.popups.text }

          Column {
            width: parent.width
            spacing: Style.space(6)

            Item {
              width: parent.width
              implicitHeight: Math.max(speedHeader.implicitHeight, speedValue.implicitHeight)

              PanelSectionHeader {
                id: speedHeader
                text: "POINTER SPEED"
                foreground: Color.popups.text
                fontFamily: Style.font.family
                anchors.left: parent.left
              }

              Text {
                id: speedValue
                text: root.signed(speedSlider.dragging ? speedSlider.liveValue : root.displayedSpeed)
                color: Qt.darker(Color.popups.text, 1.4)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            PanelSlider {
              id: speedSlider
              width: parent.width
              bar: root.palette
              minimum: -1
              maximum: 1
              step: 0.05
              tickCount: 5
              value: root.displayedSpeed
              onMoved: function(value) { root.preview(value) }
              onReleased: function(value) { root.commit(value) }
            }
          }

          PanelSeparator { foreground: Color.popups.text }

          Column {
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "PRESETS"
              foreground: Color.popups.text
              fontFamily: Style.font.family
            }

            Grid {
              id: presetGrid
              width: parent.width
              columns: 4
              spacing: Style.spacing.xs
              readonly property real cellWidth: (width - spacing * 3) / 4

              Repeater {
                model: root.presets

                Button {
                  required property var modelData
                  required property int index
                  width: presetGrid.cellWidth
                  text: modelData.name
                  fontSize: Style.font.caption
                  foreground: Color.popups.text
                  fontFamily: Style.font.family
                  bordered: true
                  selected: Math.abs(root.displayedSpeed - modelData.value) < 0.001
                  onClicked: root.commit(modelData.value)
                }
              }
            }
          }

          PanelSeparator { foreground: Color.popups.text }

          Toggle {
            width: parent.width
            label: "Show in status bar"
            description: "Optional quick access beside the system controls"
            checked: root.service ? root.service.showInBar : false
            foreground: Color.popups.text
            accent: Color.accent
            fontFamily: Style.font.family
            onClicked: if (root.service) root.service.setBarVisible(!checked)
          }
        }
      }
    }
  }
}
