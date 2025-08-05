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
    // setTime(getCurrentTime());
  }, 1000);

  onCleanup(() => {
    clearInterval(interval);
  });

  return (
    <View
      style={{
        bg_color: { hex: "#c0c0c0" },
      }}
      border={{
        where: {
          left: true,
        },
        fg_color: { hex: "#6d6d6d" },
        type: BorderType.HugVerticalFlipped,
      }}
      padding={{
        left: 1,
      }}
    >
      <Text
        fg_color={{ hex: "#222" }}
        bg_color={{ hex: "#c0c0c0" }}
        bold
        ul_style={UnderlineType.Double}
        ul_color={{ hex: "#dfdfdf" }}
      >
        ⏲ {time()}
      </Text>
      <Text fg_color={{ hex: "#dfdfdf" }} bg_color={{ hex: "#c0c0c0" }} bold>
        ▐
      </Text>
    </View>
  );
}
