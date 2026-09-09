import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  readonly property int frameCount: 825
  readonly property int frameInterval: 50
  property int currentFrame: 0

  function frameUrl(index) {
    return Qt.resolvedUrl("assets/frames/frame_" + ("0000" + (index + 1)).slice(-4) + ".png")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Item {
    id: button
    readonly property real margin: Style.spaceReal(7.5)
    implicitWidth: icon.width + margin * 2
    implicitHeight: root.barSize

    Image {
      id: icon
      anchors.centerIn: parent
      width: 18
      height: 18
      source: root.frameUrl(root.currentFrame)
      sourceSize: Qt.size(36, 36)
      fillMode: Image.PreserveAspectFit
      smooth: true
    }

    Image {
      id: warmer
      visible: false
      sourceSize: Qt.size(36, 36)
      asynchronous: true
    }

    Timer {
      interval: 5
      repeat: true
      running: true
      property int warmIndex: 0
      onTriggered: {
        warmer.source = root.frameUrl(warmIndex)
        warmIndex += 5
        if (warmIndex >= root.frameCount) running = false
      }
    }

    Timer {
      interval: root.frameInterval
      repeat: true
      running: true
      onTriggered: root.currentFrame = (root.currentFrame + 1) % root.frameCount
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (!root.bar) return
        if (mouse.button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
        else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
      }
    }
  }
}
