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
} from "@mold/core";

import { createSignal, useContext } from "solid-js";
import Colors from "../styleSheet";
import { WindowsContext } from "../WindowsContext";

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

const StartMenuButton = ({
  icon,
  label,
  hasArrow = false,
  iconColor,
  bgColor,
  pad,
  onClick,
}: StartMenuButtonProps) => {
  return (
    <View
      debug_id={`start-menu-button-${label.toLowerCase().replace(" ", "-")}`}
      sizing={{
        w: { type: SizingType.Grow },
      }}
      style={{
        bg_color: { hex: bgColor || Colors.taskbarBackground },
      }}
      padding={{
        top: 1,
        left: 1,
        right: 1,
      }}
      child_layout={{
        child_gap: pad ? 1 : 2,
      }}
      onClick={onClick}
    >
      <Text
        fg_color={iconColor ? { hex: iconColor } : undefined}
        bg_color={{
          hex: bgColor || Colors.taskbarBackground,
        }}
      >
        {icon}
      </Text>
      <Text
        fg_color={{ hex: Colors.text }}
        bg_color={{
          hex: bgColor || Colors.taskbarBackground,
        }}
      >
        {label}
      </Text>
      {hasArrow && (
        <>
          <View sizing={{ w: { type: SizingType.Grow } }} />
          <Text
            fg_color={{ hex: Colors.text }}
            bg_color={{
              hex: bgColor || Colors.taskbarBackground,
            }}
          >
            ▶
          </Text>
        </>
      )}
    </View>
  );
};

export default function ProgramsMenu() {
  const { setNotepadOpen, setStartMenuOpen } = useContext(WindowsContext);
  return (
    <View
      debug_id="start-menu-container"
      sizing={{
        h: { type: SizingType.Fit },
        w: { type: SizingType.Fit },
      }}
      position={{
        offset: { x: 0, y: 0 },
        attach_to: PositionAttachTo.Parent,
        attach_points: {
          parent: AttachPoints.RightBottom,
          element: AttachPoints.LeftBottom,
        },
      }}
      child_layout={{
        direction: LayoutDirection.topToBottom,
      }}
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
          <StartMenuButton pad icon="🗄️" label="Cabinet" />
          <StartMenuButton pad icon="🗂️" label="File Explorer" />
          <StartMenuButton
            pad
            icon="🗒️"
            label="Notepad"
            onClick={() => {
              setNotepadOpen(true);
              setStartMenuOpen(false);
            }}
          />
          <StartMenuButton pad icon="🌐" label="Internet" />
        </View>
      </View>
    </View>
  );
}
