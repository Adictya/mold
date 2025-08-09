import {
  AttachPoints,
  PositionAttachTo,
  Text,
  useDraggable,
  View,
  type Vector2,
} from "@mold/core";
import { createEffect, createSignal, For, onCleanup, onMount } from "solid-js";
import ErrorDialog from "./Error";
import Colors from "../styleSheet";

export default function ErrorsGalore() {
  const draggable = useDraggable("error", { x: 0, y: 0 }, { x: 60, y: 8 });
  const [errors, setErrors] = createSignal<Vector2[]>([]);

  // var interval: any;

  // onMount(() => {
  //   interval = setInterval(() => {
  //     draggable.updatePosition((cur) => ({
  //       x: cur.y > 50 ? cur.x + 10: cur.x ,
  //       y: cur.y > 50 ? 0 : cur.y +1,
  //     }));
  //   }, 1);
  // });
  //
  // createEffect(() => {
  //   if (errors().length > 400) {
  //     clearInterval(interval);
  //   }
  // });

  // onCleanup(() => {
  //   clearInterval(interval);
  // });

  createEffect(() => {
    const { x, y } = draggable.position();
    setErrors((errs) => [...errs, { x, y }]);
  });

  return (
    <>
      <View
        debug_id="ErrorsGalore-counter"
        position={{
          offset: { x: 15, y: 0 },
          attach_to: PositionAttachTo.Root,
          attach_points: {
            parent: AttachPoints.LeftTop,
            element: AttachPoints.LeftTop,
          },
          z_index: 10,
        }}
        padding={{
          left: 0,
        }}
        style={{
          bg_color: { hex: Colors.text },
        }}
      >
        <Text
          fg_color={{ hex: Colors.lightBorder }}
          bg_color={{ hex: Colors.text }}
        >
          | Errors: {errors().length}
        </Text>
      </View>
      <For each={errors()}>
        {(err, i) => {
          if (i() % 3 == 0)
            return <ErrorDialog debug_id="error-shadow" position={() => err} />;
        }}
      </For>
      <ErrorDialog
        position={draggable.position}
        handleMouse={draggable.handleMouse}
      />
    </>
  );
}
