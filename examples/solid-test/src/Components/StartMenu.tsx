import MoldCore, {
  addListener,
  AttachPoints,
  BorderType,
  LayoutDirection,
  PositionAttachTo,
  SizingType,
  Text,
  UnderlineType,
  View,
  Show,
} from "@mold/core";

import { createSignal } from "solid-js";
import Colors from "../styleSheet";
import ProgramsMenu from "./ProgramsMenu";

const Split = ({ text, boldTill }: { text: string; boldTill: number }) => {
  return (
    <>
      {text.split("").map((t, i) => (
        <Text
          bold={i < boldTill}
          italic={i >= boldTill}
          bg_color={{ hex: Colors.headerBlue }}
        >
          {` ${t}`}
        </Text>
      ))}
    </>
  );
};

interface StartMenuButtonProps {
  icon: string;
  label: string;
  hasArrow?: boolean;
  iconColor?: string;
  bgColor?: string;
  pad?: boolean;
  onClick?: () => void;
}

const StartMenuButton = (props: StartMenuButtonProps) => {
  return (
    <View
      debug_id={`start-menu-button-${props.label
        .toLowerCase()
        .replace(" ", "-")}`}
      sizing={{
        w: { type: SizingType.Grow },
      }}
      style={{
        bg_color: { hex: props.bgColor || Colors.taskbarBackground },
      }}
      padding={{
        top: 1,
        bottom: 1,
        left: 2,
        right: props.hasArrow ? 2 : undefined,
      }}
      child_layout={{
        child_gap: props.pad ? 1 : 2,
      }}
      onClick={props.onClick}
    >
      <Text
        fg_color={props.iconColor ? { hex: props.iconColor } : undefined}
        bg_color={{
          hex: props.bgColor || Colors.taskbarBackground,
        }}
      >
        {props.icon}
      </Text>
      <Text
        fg_color={{ hex: Colors.text }}
        bg_color={{
          hex: props.bgColor || Colors.taskbarBackground,
        }}
      >
        {props.label}
      </Text>
      {props.hasArrow && (
        <>
          <View sizing={{ w: { type: SizingType.Grow } }} />
          <Text
            fg_color={{ hex: Colors.text }}
            bg_color={{
              hex: props.bgColor || Colors.taskbarBackground,
            }}
          >
            ▶
          </Text>
        </>
      )}
    </View>
  );
};

const ProgramsButton = () => {
  const [active, setActive] = createSignal(false);

  const bg_color = () => ({
    hex: active() ? Colors.taskbarBackgroundDark : Colors.taskbarBackground,
  });
  return (
    <View
      debug_id={`start-menu-button-programs`}
      sizing={{
        w: { type: SizingType.Grow },
      }}
      style={{
        bg_color: bg_color(),
      }}
      padding={{
        top: 1,
        bottom: 1,
        left: 2,
        right: 2,
      }}
      child_layout={{
        child_gap: 1,
      }}
      onClick={() => {
        setActive((a) => !a);
      }}
    >
      <Show when={active()}>
        <ProgramsMenu />
      </Show>
      <Text bg_color={bg_color()}>🗂️</Text>
      <Text fg_color={{ hex: Colors.text }} bg_color={bg_color()}>
        Programs
      </Text>
      <View sizing={{ w: { type: SizingType.Grow } }} />
      <Text fg_color={{ hex: Colors.text }} bg_color={bg_color()}>
        ▶
      </Text>
    </View>
  );
};

export default function StartMenu() {
  return (
    <View
      debug_id="start-menu-container"
      sizing={{
        h: { type: SizingType.Fit },
        w: { type: SizingType.Fit },
      }}
      position={{
        offset: { x: 0, y: 1 },
        attach_to: PositionAttachTo.Parent,
        attach_points: {
          parent: AttachPoints.LeftTop,
          element: AttachPoints.LeftBottom,
        },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
			onClick={() => {}}
    >
      <View
        debug_id="start-menu-content-container"
        sizing={{
          h: { minmax: { min: 1, max: 1 } },
          w: { type: SizingType.Grow },
        }}
        style={{
          bg_color: { hex: Colors.desktopBackground },
        }}
        border={{
          type: BorderType.HugHorizontalFlipped,
          fg_color: { hex: Colors.lightBorder },
          where: {
            top: true,
          },
        }}
      />
      <View
        debug_id="start-menu-content-container"
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
          sizing={{
            h: { type: SizingType.Grow },
            w: { minmax: { min: 3, max: 3 } },
          }}
          style={{
            bg_color: { hex: Colors.headerBlue },
          }}
          child_layout={{
            direction: LayoutDirection.topToBottom,
          }}
          padding={{
            left: 0,
            top: 8,
          }}
					scroll={{
						horizontal: true,
					}}
        >
          <Split text="Moldows 98" boldTill={7} />
          <Text
            fg_color={{ hex: Colors.darkBorder }}
            bg_color={{ hex: Colors.headerBlue }}
          >
            ▂▂▂
          </Text>
        </View>
        <View
          debug_id="start-menu-bottom-border"
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
            // child_gap: 1,
          }}
        >
          <View
            debug_id="start-menu-buttons-spacer"
            sizing={{
              h: { type: SizingType.Grow },
            }}
          />
          <StartMenuButton pad icon="💼" label="Documents" hasArrow />
          <ProgramsButton />
          <StartMenuButton pad icon="🔍" label="Find" hasArrow />
          <StartMenuButton pad icon="📕" label="Help" />
          {/* <StartMenuButton icon="⍰" label="Help" iconColor="#A020F0" /> */}
          <StartMenuButton pad icon="🔓" label="Log Off" />
          <StartMenuButton icon="⏻" label="Shutdown" iconColor="#a22" onClick={() => {
						MoldCore.shutdown();
						process.exit(0);
					}} />
        </View>
      </View>
    </View>
  );
}
