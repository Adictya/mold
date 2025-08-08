import {
  addListener,
  AttachPoints,
  BorderType,
  LayoutDirection,
  PositionAttachTo,
  SizingType,
  Text,
  UnderlineType,
  View,
  useDraggable,
  type MouseEventHandler,
  type Vector2,
} from "@mold/core";

import { createSignal, For, useContext, type Accessor } from "solid-js";
import Colors from "../styleSheet";
import { WindowsContext } from "../WindowsContext";

const warningTriangle = [
  ["▄"],
  ["▟", " ", "▙"],
  ["▟", "▉", "▄", "▉", "▙"],
  ["▟", "▉", "▉", "▄", "▉", "▉", "▙"],
];

const OkButton = (props: { debug_id?: string }) => {
  return (
    <View
      debug_id={props.debug_id}
      position={{
        attach_to: PositionAttachTo.Parent,
        attach_points: {
          element: AttachPoints.CenterCenter,
          parent: AttachPoints.CenterCenter,
        },
        offset: {
          y: 2,
        },
      }}
      style={{
        bg_color: { hex: Colors.taskbarBackground },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
    >
      <View
        debug_id={props.debug_id}
        sizing={{
          h: { minmax: { min: 1, max: 1 } },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.taskbarBackground },
        }}
        border={{
          where: {
            top: true,
          },
          fg_color: { hex: Colors.lightBorder },
          type: BorderType.HugHorizontalFlipped,
        }}
      />
      <View debug_id={props.debug_id}>
        <Text
          debug_id={props.debug_id}
          bg_color={{ hex: Colors.taskbarBackground }}
          fg_color={{ hex: Colors.mediumLightBorder }}
          ul_color={{ hex: Colors.mediumBorder }}
          ul_style={UnderlineType.Double}
        >
          ▌
        </Text>
        <Text
          debug_id={props.debug_id}
          bg_color={{ hex: Colors.taskbarBackground }}
          fg_color={{ hex: Colors.text }}
          ul_color={{ hex: Colors.mediumBorder }}
          ul_style={UnderlineType.Double}
        >
          {"  OK  "}
        </Text>
        <Text
          debug_id={props.debug_id}
          bg_color={{ hex: Colors.taskbarBackground }}
          fg_color={{ hex: Colors.text }}
          ul_color={{ hex: Colors.mediumBorder }}
          ul_style={UnderlineType.Double}
        >
          ▐
        </Text>
      </View>
    </View>
  );
};

const HeaderButton = (props: {
  icon: string;
  onClick?: () => void;
  debug_id?: string;
}) => {
  return (
    <View
      debug_id={props.debug_id}
      style={{
        bg_color: { hex: Colors.headerBlue },
      }}
      border={{
        where: {
          left: true,
        },
        fg_color: { hex: Colors.mediumLightBorder },
        type: BorderType.HugHorizontalFlipped,
      }}
      onClick={props.onClick}
    >
      <Text
        debug_id={props.debug_id}
        bg_color={{ hex: Colors.taskbarBackground }}
        fg_color={{ hex: Colors.text }}
        ul_color={{ hex: Colors.darkBorder }}
        ul_style={UnderlineType.Double}
      >
        {` ${props.icon} `}
      </Text>
      <Text
        debug_id={props.debug_id}
        fg_color={{ hex: Colors.darkBorder }}
        bg_color={{ hex: Colors.taskbarBackground }}
        ul_color={{ hex: Colors.darkBorder }}
        ul_style={UnderlineType.Double}
      >
        ▐
      </Text>
    </View>
  );
};

export default function ErrorDialog(props: {
  debug_id?: string;
  handleMouse?: MouseEventHandler;
  position: Accessor<Vector2>;
}) {
  return (
    <View
      debug_id={props.debug_id}
      sizing={{
        w: { minmax: { min: 38, max: 34 } },
        h: { minmax: { min: 10, max: 10 } },
      }}
      position={{
        offset: { x: props.position().x, y: props.position().y },
        attach_to: PositionAttachTo.Root,
        attach_points: {
          parent: AttachPoints.LeftTop,
          element: AttachPoints.LeftTop,
        },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
      onMouse={props.handleMouse}
    >
      <View
        debug_id={props.debug_id}
        sizing={{
          h: { minmax: { min: 1, max: 1 } },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.desktopBackground },
        }}
        border={{
          where: {
            top: true,
          },
          fg_color: { hex: Colors.lightBorder },
          type: BorderType.HugHorizontalFlipped,
        }}
      />
      <View
        debug_id={props.debug_id}
        sizing={{
          h: { minmax: { min: 1, max: 1 } },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.headerBlue },
        }}
        border={{
          where: {
            left: true,
            right: false,
          },
          fg_color: { hex: Colors.lightBorder },
          type: BorderType.HugVerticalFlipped,
        }}
      >
        <View debug_id={props.debug_id}>
          <Text
            debug_id={props.debug_id}
            bg_color={{ hex: Colors.headerBlue }}
            fg_color={{ hex: "#fff" }}
          >
            Error
          </Text>
        </View>
        <View
          debug_id={props.debug_id}
          sizing={{
            h: { minmax: { min: 1, max: 1 } },
            w: { type: SizingType.Grow },
          }}
          style={{
            bg_color: { hex: Colors.headerBlue },
          }}
        />
        <HeaderButton icon="⚔︎" debug_id={props.debug_id} />
        <Text
          debug_id={props.debug_id}
          fg_color={{ hex: Colors.darkBorder }}
          bg_color={{ hex: Colors.headerBlue }}
        >
          ▐
        </Text>
      </View>
      <View
        debug_id={props.debug_id}
        sizing={{
          h: { type: SizingType.Grow },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.taskbarBackground },
        }}
        border={{
          type: BorderType.HugVerticalFlipped,
          fg_color: { hex: Colors.lightBorder },
          where: {
            left: true,
            right: false,
            top: false,
            bottom: false,
          },
        }}
        padding={{
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
        }}
      >
        <View
          debug_id={props.debug_id}
          sizing={{
            h: { type: SizingType.Grow },
            w: { type: SizingType.Grow },
          }}
          style={{
            bg_color: { hex: Colors.taskbarBackground },
          }}
          border={{
            where: {
              right: true,
              bottom: true,
            },
            fg_color: { hex: Colors.mediumBorder },
            type: BorderType.HugVerticalFlipped,
          }}
          child_layout={{
            direction: LayoutDirection.leftToRight,
            child_gap: 2,
          }}
        >
          <View
            debug_id={props.debug_id}
            style={{
              bg_color: { hex: Colors.taskbarBackground },
            }}
            child_layout={{
              direction: LayoutDirection.topToBottom,
            }}
          >
            {warningTriangle.map((row, index) => {
              return (
                <View
                  debug_id={props.debug_id}
                  padding={{
                    left: warningTriangle.length - index,
                  }}
                  style={{
                    bg_color: { hex: Colors.taskbarBackground },
                  }}
                >
                  {row.map((char, i) => (
                    <Text
                      debug_id={props.debug_id}
                      bg_color={{
                        hex:
                          index == i && i !== 0
                            ? Colors.text
                            : Colors.taskbarBackground,
                      }}
                      fg_color={{ hex: "#fce008" }}
                    >
                      {char}
                    </Text>
                  ))}
                </View>
              );
            })}
          </View>
          <View
            debug_id={props.debug_id}
            style={{
              bg_color: { hex: Colors.taskbarBackground },
            }}
            padding={{
              top: 2,
            }}
          >
            <Text
              debug_id={props.debug_id}
              fg_color={{ hex: Colors.text }}
              bg_color={{ hex: Colors.taskbarBackground }}
            >
              An error has occured
            </Text>
          </View>
          <OkButton debug_id={props.debug_id} />
        </View>
      </View>
    </View>
  );
}
