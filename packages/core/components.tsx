/* @refresh skip */
import { children as resolveChildren } from "solid-js";

export enum BorderType {
  SingleRounded = 0,
  SingleSquare = 1,
  doubleSquare = 2,
  ThickSquare = 3,
  ThinSquare = 4,
  HugVertical = 5,
  HugVerticalFlipped = 6,
  HugHorizontal = 7,
  HugHorizontalFlipped = 8,
}

export enum SizingType {
  Fit = 0,
  Grow = 1,
  Percent = 2,
  Fixed = 3,
}

export enum LayoutAlignmentX {
  left = 0,
  right = 1,
  center = 2,
}

export enum LayoutAlignmentY {
  top = 0,
  bottom = 1,
  center = 2,
}

export enum LayoutDirection {
  leftToRight = 0,
  topToBottom = 1,
}

export enum AttachPoints {
  LeftTop = 0,
  LeftCenter = 1,
  LeftBottom = 2,
  CenterTop = 3,
  CenterCenter = 4,
  CenterBottom = 5,
  RightTop = 6,
  RightCenter = 7,
  RightBottom = 8,
}

export enum UnderlineType {
  Off = 0,
  Single = 1,
  Double = 2,
  Curly = 3,
  Dotted = 4,
  Dashed = 5,
}

type Color = { hex: string };

type ViewProps = {
  position?: {
    offset?: { x?: number; y?: number };
    parentId?: string;
    z_index?: number;
    attach_points?: { element?: AttachPoints; parent?: AttachPoints };
  };
  sizing?: {
    w?: {
      minmax?: { min?: number; max?: number };
      /** Percentage of parent container size (0.0-1.0) */
      percent?: number;
      type?: SizingType;
    };
    h?: {
      minmax?: { min?: number; max?: number };
      /** Percentage of parent container size (0.0-1.0) */
      percent?: number;
      type?: SizingType;
    };
  };
  padding?: {
    left?: number;
    right?: number;
    top?: number;
    bottom?: number;
  };
  child_layout?: {
    child_gap?: number;
    child_alignment?: {
      x?: LayoutAlignmentX;
      y?: LayoutAlignmentY;
    };
    direction?: LayoutDirection;
  };
  scroll?: {
    horizontal?: boolean;
    vertical?: boolean;
    child_offset?: { x?: number; y?: number };
  };
  style?: {
    bg_color?: Color;
  };
  border?: {
    where?: {
      top?: boolean;
      bottom?: boolean;
      left?: boolean;
      right?: boolean;
    };
    type?: BorderType;
    fg_color?: Color;
    bg_color?: Color;
  };
  children?: any;
  debug_id?: string;
  onClick?: (event: any) => void;
};

export const View = (props: ViewProps) => {
  const resolved = resolveChildren(() => props.children);

  return (
    <div
      position={props.position}
      sizing={props.sizing}
      padding={props.padding}
      childLayout={props.child_layout}
      scroll={props.scroll}
      style={props.style}
      border={props.border}
      debug_id={props.debug_id}
      onClick={props.onClick}
    >
      {resolved()}
    </div>
  );
};

type TextProps = {
  fg_color?: Color;
  bg_color?: Color;
  ul_color?: Color;
  ul_style?: UnderlineType;

  bold?: boolean;
  dim?: boolean;
  italic?: boolean;
  blink?: boolean;
  reverse?: boolean;
  invisible?: boolean;
  strikethrough?: boolean;

  children: string | string[];
  debug_id?: string;
};

export const Text = ({ children, debug_id, ...props }: TextProps) => {
  const resolved = resolveChildren(() => children);
  return (
    <span text={resolved()} textStyle={{ ...props }} debug_id={debug_id} />
  );
};
