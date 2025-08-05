import {
  BorderType,
  LayoutDirection,
  Text,
  UnderlineType,
  View,
} from "@mold/core";
import { createSignal } from "solid-js";
import Colors from "../styleSheet";

const lb = Colors.lightBorder;
const db = Colors.darkBorder;

export default function StartButton() {
  const [active, setActive] = createSignal(false);
  return (
    <View
      debug_id="start-button-container"
      style={{
        bg_color: { hex: "#c0c0c0" },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
      onClick={() => {
        setActive((a) => !a);
      }}
    >
      <View
        debug_id="start-button"
        style={{
          bg_color: { hex: "#c0c0c0" },
        }}
        border={{
          where: {
            left: true,
          },
          fg_color: { hex: active() ? db : lb },
          type: BorderType.HugVerticalFlipped,
        }}
        padding={{
          left: 1,
        }}
      >
        <Text
          debug_id="start-text"
          bg_color={{ hex: "#c0c0c0" }}
          fg_color={{ hex: "#222" }}
          bold
          ul_style={UnderlineType.Double}
          ul_color={{ hex: active() ? lb : db }}
        >
          ⛴︎ Start2
        </Text>
        <Text
          debug_id="start-text-border"
          bg_color={{ hex: "#c0c0c0" }}
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
