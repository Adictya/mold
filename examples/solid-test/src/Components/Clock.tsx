import MoldCore, {
  addListener,
  AttachPoints,
  BorderType,
  LayoutAlignmentX,
  LayoutAlignmentY,
  LayoutDirection,
  SizingType,
  Text,
  UnderlineType,
  View,
} from "@mold/core";
import { createSignal, onCleanup } from "solid-js";
import Colors from "../styleSheet";

function getCurrentTime() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const seconds = String(now.getSeconds()).padStart(2, "0");
  // const millis = String(now.getMilliseconds()).padStart(4, "0");

  return `${hours}:${minutes}:${seconds}`;
  // return `${hours}:${minutes}:${seconds}:${millis}`;
}

export default function Clock() {
  const [time, setTime] = createSignal(getCurrentTime());

  const interval = setInterval(() => {
    setTime(getCurrentTime());
  }, 1000);

  onCleanup(() => {
    clearInterval(interval);
  });

  return (
    <View
      debug_id="clock-container"
      style={{
        bg_color: { hex: Colors.desktopBackground },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
    >
      <View
        debug_id="clock-top-border"
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
          fg_color: { hex: Colors.darkBorder },
          type: BorderType.HugHorizontalFlipped,
        }}
      />
      <View
        style={{
          bg_color: { hex: Colors.taskbarBackground },
        }}
        border={{
          where: {
            left: true,
          },
          fg_color: { hex: Colors.mediumBorder },
          type: BorderType.HugVerticalFlipped,
        }}
      >
        <Text
          fg_color={{ hex: Colors.text }}
          bg_color={{ hex: Colors.taskbarBackground }}
          bold
          ul_style={UnderlineType.Double}
          ul_color={{ hex: Colors.lightBorder }}
        >
          ⏲ {time()}
        </Text>
        <Text fg_color={{ hex: "#dfdfdf" }} bg_color={{ hex: "#c0c0c0" }} bold>
          ▐
        </Text>
      </View>
    </View>
  );
}
