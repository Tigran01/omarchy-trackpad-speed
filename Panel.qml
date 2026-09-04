import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

Panel {
  id: root
  moduleName: "io.github.tigran01.trackpad-speed"
  ipcTarget: "io.github.tigran01.trackpad-speed"

  readonly property var speedService: bar && bar.shell
    ? bar.shell.serviceFor(moduleName) : null
  property real displayedSpeed: speedService && speedService.stateLoaded
    ? speedService.speed : 0.0
  property real wheelAccumulator: 0
  property int selectedPreset: nearestPreset(displayedSpeed)
  readonly property var presets: [
    { name: "Precise", value: -0.40 },
    { name: "Natural", value: 0.00 },
    { name: "Fast", value: 0.60 },
    { name: "Swift", value: 1.00 }
  ]

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

  function commit(value, showOsd) {
    preview(value)
    if (speedService) speedService.setSpeed(displayedSpeed)
    if (showOsd && bar && bar.shell) {
      bar.shell.summon("omarchy.osd", JSON.stringify({
        icon: "touchpad",
        value: Math.round((displayedSpeed + 1) * 50)
      }))
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Connections {
    target: root.speedService
    function onSpeedChanged() { root.preview(root.speedService.speed) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "󰟸" : "󰟸  " + root.signed(root.displayedSpeed)
    horizontalMargin: 7.5
    tooltipText: "Trackpad speed " + root.signed(root.displayedSpeed) + " · scroll to adjust"
    active: root.opened

    onPressed: function(mouseButton) { root.toggle() }
    onWheelMoved: function(delta) {
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps !== 0) root.commit(root.displayedSpeed + wheel.steps * 0.05, true)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.commit(root.displayedSpeed + dx * 0.05, true)
        if (dy !== 0) {
          root.selectedPreset = Math.max(0, Math.min(root.presets.length - 1, root.selectedPreset + dy))
          root.commit(root.presets[root.selectedPreset].value, true)
        }
      }
      onActivateRequested: root.commit(root.presets[root.selectedPreset].value, true)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: "󰟸"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Trackpad speed"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: root.speedService && !root.speedService.deviceAvailable
                ? "NO TRACKPAD DETECTED" : root.mood(root.displayedSpeed)
              color: root.speedService && !root.speedService.deviceAvailable
                ? root.bar.urgent : Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Math.max(speedHeader.implicitHeight, speedValue.implicitHeight)

            PanelSectionHeader {
              id: speedHeader
              text: "POINTER SPEED"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: speedValue
              text: root.signed(speedSlider.dragging ? speedSlider.liveValue : root.displayedSpeed)
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          PanelSlider {
            id: speedSlider
            width: parent.width
            bar: root.bar
            minimum: -1
            maximum: 1
            step: 0.05
            tickCount: 5
            value: root.displayedSpeed
            onMoved: function(value) { root.preview(value) }
            onReleased: function(value) { root.commit(value, true) }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "PRESETS"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
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
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                bordered: true
                selected: Math.abs(root.displayedSpeed - modelData.value) < 0.001
                hasCursor: root.selectedPreset === index
                onClicked: root.commit(modelData.value, true)
                onHovered: function(hovered) { if (hovered) root.selectedPreset = index }
              }
            }
          }
        }

        Text {
          width: parent.width
          text: "Scroll the bar item or use ← / → for fine control"
          color: Qt.darker(root.bar.foreground, 1.5)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
