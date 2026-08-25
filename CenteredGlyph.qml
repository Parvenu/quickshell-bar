pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property string glyph
    required property color color
    required property string fontFamily
    required property int fontPixelSize

    property int fontWeight: Font.Normal
    property real opticalHorizontalOffset: 0

    TextMetrics {
        id: glyphMetrics

        font: glyphLabel.font
        text: root.glyph
    }

    Text {
        id: glyphLabel

        x: (root.width - glyphMetrics.tightBoundingRect.width) / 2
            - glyphMetrics.tightBoundingRect.x
            + root.opticalHorizontalOffset
        y: (root.height - glyphMetrics.tightBoundingRect.height) / 2
            - baselineOffset
            - glyphMetrics.tightBoundingRect.y
        text: root.glyph
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontPixelSize
        font.weight: root.fontWeight
    }
}
