import {
  BorderType,
  LayoutDirection,
  SizingType,
  Text,
  UnderlineType,
  View,
  Show,
} from "@mold/core";
import { useContext } from "solid-js";
import Colors from "../styleSheet";
import StartMenu from "./StartMenu";
import { WindowsContext } from "../WindowsContext";

const lb = Colors.lightBorder;
const db = Colors.darkBorder;

export default function StartButton() {
  const { startMenuOpen: active, setStartMenuOpen: setActive } =
    useContext(WindowsContext);

  return (
    <View
      debug_id="start-button-container"
      style={{
        bg_color: { hex: active() ? "#c0c0c0" : "#808080" },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
      onClick={() => {
        setActive((a: boolean) => !a);
      }}
    >
      <Show when={active()}>
        <StartMenu />
      </Show>
      <View
        debug_id="start-button-top-border"
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
          fg_color: { hex: active() ? db : lb },
          type: BorderType.HugHorizontalFlipped,
        }}
      />
      <View
        debug_id="start-button"
        style={{
          bg_color: { hex: Colors.taskbarBackground },
        }}
      >
        <Text
          debug_id="start-text-left-border"
          bg_color={{
            hex: active()
              ? Colors.taskbarBackgroundDark
              : Colors.taskbarBackground,
          }}
          fg_color={{ hex: active() ? Colors.mediumBorder : lb }}
          bold
          ul_style={UnderlineType.Double}
          ul_color={{ hex: active() ? lb : Colors.mediumBorder }}
        >
          ▌
        </Text>
        <Text
          debug_id="start-text"
          bg_color={{
            hex: active()
              ? Colors.taskbarBackgroundDark
              : Colors.taskbarBackground,
          }}
          fg_color={{ hex: Colors.text }}
          ul_style={UnderlineType.Double}
          ul_color={{ hex: active() ? lb : db }}
          bold
        >
          ⛴︎ Start
        </Text>
        <Text
          debug_id="start-text-border"
          bg_color={{
            hex: active()
              ? Colors.taskbarBackgroundDark
              : Colors.taskbarBackground,
          }}
          fg_color={{ hex: active() ? lb : db }}
          bold
          ul_style={UnderlineType.Double}
          ul_color={{ hex: active() ? lb : db }}
        >
          ▐
        </Text>
      </View>
    </View>
  );
}
