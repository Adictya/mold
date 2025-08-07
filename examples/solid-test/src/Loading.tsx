import {
  AttachPoints,
  BorderType,
  For,
  LayoutDirection,
  PositionAttachTo,
  SizingType,
  Text,
  View,
} from "@mold/core";
import Colors from "./styleSheet";
import { createSignal, onCleanup } from "solid-js";

const MoldBanner = [
  [
    "##::::'##:",
    "###::'###:",
    "####'####:",
    "## ### ##:",
    "##. #: ##:",
    "##:.:: ##:",
    "##:::: ##:",
    ".:::::..::",
  ],
  [
    ":#######::",
    "##.... ##:",
    "##:::: ##:",
    "##:::: ##:",
    "##:::: ##:",
    "##:::: ##:",
    ".#######::",
    ":......:::",
  ],
  [
    "##:::::::",
    "##:::::::",
    "##:::::::",
    "##:::::::",
    "##:::::::",
    "##:::::::",
    "########:",
    "........::",
  ],
  [
    "########::",
    "##.... ##:",
    "##:::: ##:",
    "##:::: ##:",
    "##:::: ##:",
    "##:::: ##:",
    "########::",
    "........::",
  ],
];

export default function Loading() {
  const [shift, setShift] = createSignal(0);

  const interval = setInterval(() => {
    if (shift() > 30) {
      setShift(0);
    } else {
      setShift((s) => s + 1);
    }
  }, 50);

  onCleanup(() => {
    clearInterval(interval);
  });

  return (
    <View
      debug_id="Loading-container"
      position={{
        attach_points: {
          parent: AttachPoints.CenterCenter,
          element: AttachPoints.CenterCenter,
        },
        attach_to: PositionAttachTo.Root,
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
        child_gap: 2,
      }}
    >
      <View
        child_layout={{
          direction: LayoutDirection.leftToRight,
        }}
      >
        <For each={MoldBanner}>
          {(row, i) => (
            <View
              child_layout={{
                direction: LayoutDirection.topToBottom,
              }}
            >
              <For each={row}>
                {(char, j) => <Text fg_color={{ hex: "#fff" }}>{char}</Text>}
              </For>
            </View>
          )}
        </For>
      </View>
      <View
        sizing={{
          h: { minmax: { min: 3, max: 3 } },
          w: { type: SizingType.Grow },
        }}
        border={{
          where: {
            top: true,
            bottom: true,
            left: true,
            right: true,
          },
          fg_color: { hex: "#fff" },
          type: BorderType.SingleRounded,
        }}
        padding={{
          left: shift(),
        }}
      >
        <Text fg_color={{ hex: Colors.headerBlue }}>▫️▫️▫️</Text>
      </View>
    </View>
  );
}
