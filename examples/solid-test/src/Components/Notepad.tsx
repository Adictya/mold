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
} from "@mold/core";

import { createSignal, useContext } from "solid-js";
import Colors from "../styleSheet";
import { WindowsContext } from "../WindowsContext";

const HeaderButton = (props: { icon: string; onClick?: () => void }) => {
  return (
    <View
      style={{
        bg_color: { hex: Colors.headerBlue },
      }}
      border={{
        where: {
          left: true,
        },
        fg_color: { hex: Colors.lightBorder },
        type: BorderType.HugHorizontalFlipped,
      }}
      onClick={props.onClick}
    >
      <Text
        bg_color={{ hex: Colors.taskbarBackground }}
        fg_color={{ hex: Colors.text }}
        ul_color={{ hex: Colors.darkBorder }}
        ul_style={UnderlineType.Double}
      >
        {` ${props.icon} `}
      </Text>
      <Text
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

const MenuBarButton = ({
  text,
  onClick,
}: {
  text: string;
  onClick?: () => void;
}) => {
  return (
    <View onClick={onClick}>
      <Text
        fg_color={{ hex: Colors.text }}
        bg_color={{ hex: Colors.taskbarBackground }}
        ul_color={{ hex: "#000" }}
        ul_style={UnderlineType.Single}
      >
        {text.slice(0, 1)}
      </Text>
      <Text
        fg_color={{ hex: Colors.text }}
        bg_color={{ hex: Colors.taskbarBackground }}
      >
        {text.slice(1)}
      </Text>
    </View>
  );
};

export default function Notepad() {
  const { setErrorScene, setNotepadOpen, notepadDraggable: draggable } = useContext(WindowsContext);
  const [text, setText] = createSignal(
    `Introducing MOLD!
A performance oriented TUI library for Javascript
- Write your UI with Solidjs
- powered by a Zig core implementation
- With blazing fast flex box like layouting with CLAY
- And double buffered cross-platform terminal rendering with libVaxis.




Yes it scrolls!
and wait,`,
  );

  // const draggable = useDraggable("notepad", { x: 10, y: 5 }, { x: 60, y: 8 });

  addListener((event) => {
    const { text, key } = event;
    // backspace
    if (key == 127) {
      setText((t) => t.slice(0, -1));
    } else {
      setText((t) => t + text);
    }
  });
  return (
    <View
      debug_id="Notepad-container"
      sizing={{
        w: { minmax: { min: 10, max: draggable.size().x } },
        h: { minmax: { min: draggable.size().y, max: draggable.size().y } },
        // h: { minmax: { min: 20, max: 20 } },
        // h: { minmax: { min: 8, max: 8 } },
        // w: { minmax: { min: 60, max: 60 } },
      }}
      position={{
        offset: { x: draggable.position().x, y: draggable.position().y },
        attach_to: PositionAttachTo.Root,
        attach_points: {
          parent: AttachPoints.LeftTop,
          element: AttachPoints.LeftTop,
        },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
      onMouse={draggable.handleMouse}
    >
      <View
        debug_id="Notepad-header"
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
        debug_id="Notepad-content-header"
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
        <View>
          <Text
            bg_color={{ hex: Colors.headerBlue }}
            fg_color={{ hex: "#fff" }}
          >
            ⚿ Notepad
          </Text>
        </View>
        <View
          sizing={{
            h: { minmax: { min: 1, max: 1 } },
            w: { type: SizingType.Grow },
          }}
          style={{
            bg_color: { hex: Colors.headerBlue },
          }}
        />
        <HeaderButton icon="-" />
        <HeaderButton icon="□" />
        <HeaderButton
          icon="⚔︎"
          onClick={() => {
            setNotepadOpen(false);
						setErrorScene(true);
          }}
        />
        <Text
          fg_color={{ hex: Colors.darkBorder }}
          bg_color={{ hex: Colors.headerBlue }}
        >
          ▐
        </Text>
      </View>
      <View
        debug_id="Notepad-content-container"
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
          debug_id="Notepad-bottom-border"
          sizing={{
            h: { type: SizingType.Grow },
            w: { type: SizingType.Grow },
          }}
          style={{
            bg_color: { hex: Colors.taskbarBackground },
          }}
          border={{
            where: {
              left: false,
              right: true,
              top: false,
              bottom: true,
            },
            fg_color: { hex: Colors.mediumBorder },
            type: BorderType.HugVerticalFlipped,
          }}
          child_layout={{
            direction: LayoutDirection.topToBottom,
          }}
        >
          <View
            debug_id="Notepad-file-menu"
            sizing={{
              w: { type: SizingType.Grow },
            }}
            style={{
              bg_color: { hex: Colors.taskbarBackground },
            }}
            child_layout={{
              child_gap: 2,
            }}
          >
            <MenuBarButton text="File" />
            <MenuBarButton text="Edit" />
            <MenuBarButton text="View" />
            <MenuBarButton text="Help" />
          </View>
          <View
            debug_id="Notepad-content-top-border"
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
              fg_color: { hex: Colors.darkBorder },
              type: BorderType.HugHorizontalFlipped,
            }}
          />
          <View
            debug_id="Notepad-content-container"
            sizing={{
              h: { type: SizingType.Grow },
              w: { minmax: { min: 6, max: draggable.size().x - 2 } },
            }}
            style={{
              bg_color: { hex: "#fff" },
            }}
            border={{
              where: {
                left: true,
              },
              fg_color: { hex: Colors.mediumBorder },
              type: BorderType.HugVerticalFlipped,
            }}
            scroll={{
              vertical: true,
            }}
          >
            <Text fg_color={{ hex: Colors.text }} bg_color={{ hex: "#fff" }}>
              {text()}
            </Text>
          </View>
        </View>
      </View>
    </View>
  );
}
