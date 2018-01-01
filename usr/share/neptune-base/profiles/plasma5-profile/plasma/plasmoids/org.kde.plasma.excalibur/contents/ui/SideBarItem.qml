/***************************************************************************
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents

import "../code/tools.js" as Tools

Item {
    id: item

    width: parent.width
    height: itemHeight

    signal actionTriggered(string actionId, variant actionArgument)
    signal aboutToShowActionMenu(variant actionMenu)
    signal flick(int xdelta, int ydelta)

    property bool hasActionList: ((model.favoriteId != null)
        || (("hasActionList" in model) && (model.hasActionList != null)))
    property int itemIndex: model.index
    property bool isCurrent: false
    
     property int itemHeight: Math.ceil((Math.max(theme.mSize(theme.defaultFont).height, units.iconSizes.medium)
        + Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
        listItemSvg.margins.top + listItemSvg.margins.bottom)) / 2) * 2

    onAboutToShowActionMenu: {
        var actionList = (model.hasActionList != null) ? model.actionList : [];
        Tools.fillActionMenu(actionMenu, actionList, repeater.model, model.favoriteId);
    }

    onActionTriggered: {
        Tools.triggerAction(repeater.model, model.index, actionId, actionArgument);
    }

    function openActionMenu(visualParent, x, y) {
        aboutToShowActionMenu(actionMenu);
        actionMenu.visualParent = visualParent;
        actionMenu.open(x, y);
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: {
            actionTriggered(actionId, actionArgument);
        }
    }
    
    //
    
     Row {
        anchors.left: parent.left
        anchors.leftMargin: highlightItemSvg.margins.left
        anchors.right: parent.right
        anchors.rightMargin: highlightItemSvg.margins.right

        height: item.height

        spacing: units.smallSpacing * 2

        LayoutMirroring.enabled: (Qt.application.layoutDirection == Qt.RightToLeft)

        PlasmaCore.IconItem {
            id: icon

            anchors.verticalCenter: parent.verticalCenter

            width: units.iconSizes.medium
            height: width

            //animated: false
            usesPlasmaTheme: repeater.usesPlasmaTheme

            //active: listener.containsMouse
            source: model.decoration
        }

        PlasmaComponents.Label {
            id: label

            enabled: !isParent || (isParent && hasChildren)

            anchors {
                left: icon.right
                leftMargin: units.gridUnit
            }
            y: Math.round((parent.height - label.height - ( (subTitleElement.text != "") ? subTitleElement.paintedHeight : 0) ) / 2)

            width: (parent.width - icon.width - units.gridUnit
                - ((icon.visible ? 1 : 0) * parent.spacing))

            verticalAlignment: Text.AlignVCenter

            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight

            text: model.display
        }
        PlasmaComponents.Label {
            id: subTitleElement

            anchors {
                left: label.left
                rightMargin: units.gridUnit * 2
                top: label.bottom
            }
            height: paintedHeight

            text: model.description
            opacity: isCurrent ? 0.6 : 0.3
            font.pointSize: theme.smallestFont.pointSize
            elide: Text.ElideMiddle
        }
    }

    //

    MouseEventListener {
        id: listener

        anchors {
            fill: parent
            leftMargin: - sideBar.margins.left
            rightMargin: - sideBar.margins.right
        }

        enabled: (item.parent && !item.parent.animating)

        property bool pressed: false
        property int pressX: -1
        property int pressY: -1

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: {
            if (mouse.buttons & Qt.RightButton) {
                if (item.hasActionList) {
                    item.openActionMenu(item, mouse.x, mouse.y);
                }
            } else {
                pressed = true;
                pressX = mouse.x;
                pressY = mouse.y;
            }
        }

        onReleased: {
            if (pressed) {
                repeater.model.trigger(index, "", null);
                plasmoid.expanded = false;
            }

            pressed = false;
            pressX = -1;
            pressY = -1;
        }

        onContainsMouseChanged: {
            if (!containsMouse) {
                pressed = false;
                pressX = -1;
                pressY = -1;
                highlightItemSvg.visible = false
                isCurrent = false
            }
            else {
                highlightItemSvg.parent = item
                highlightItemSvg.width = item.width
                highlightItemSvg.height = item.height
                highlightItemSvg.visible = true
                isCurrent = true
            }
        }

        onPositionChanged: {
            if (pressX != -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                kicker.dragSource = item;
                dragHelper.startDrag(kicker, model.url, model.icon);
                pressed = false;
                pressX = -1;
                pressY = -1;

                return;
            }
        }
        onWheelMoved: {
            item.flick(0, wheel.delta * 5)
        }
    }
}

