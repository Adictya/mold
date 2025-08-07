import { createContext, createSignal, useContext } from "solid-js";
import type { MouseEventHandler } from "./solid";
import { log } from "./logging";

type Vector2 = {
  x: number;
  y: number;
};

type DragState = {
  isDragging: boolean;
  draggedElementId: string | null;
  onDragEnd?: () => void;
  startPosition: Vector2;
  currentOffset: Vector2;
};

type DragContextType = {
  dragState: () => DragState;
  startDrag: (
    elementId: string,
    startPos: Vector2,
    callback: () => void,
  ) => void;
  updateDrag: (newOffset: Vector2) => void;
  endDrag: () => void;
  handleAreaMouse: MouseEventHandler;
};

const DragContext = createContext<DragContextType>({
  dragState: () => ({
    isDragging: false,
    draggedElementId: null,
    startPosition: { x: 0, y: 0 },
    currentOffset: { x: 0, y: 0 },
  }),
  startDrag: () => {},
  updateDrag: () => {},
  endDrag: () => {},
  handleAreaMouse: () => {},
});

export const DragProvider = (props: { children: any }) => {
  const [dragState, setDragState] = createSignal<DragState>({
    isDragging: false,
    draggedElementId: null,
    startPosition: { x: 0, y: 0 },
    currentOffset: { x: 0, y: 0 },
  });

  const startDrag = (
    elementId: string,
    startPos: Vector2,
    onDragEnd: () => void,
  ) => {
    if (dragState().isDragging) return;

    setDragState({
      isDragging: true,
      draggedElementId: elementId,
      startPosition: startPos,
      onDragEnd,
      currentOffset: { x: 0, y: 0 },
    });
  };

  const updateDrag = (newOffset: Vector2) => {
    if (!dragState().isDragging) return;

    setDragState((prev) => ({
      ...prev,
      currentOffset: newOffset,
    }));
  };

  const endDrag = () => {
    setDragState({
      isDragging: false,
      draggedElementId: null,
      startPosition: { x: 0, y: 0 },
      currentOffset: { x: 0, y: 0 },
    });
  };

  const handleAreaMouse: MouseEventHandler = (clayMouse, vaxisMouse) => {
    const state = dragState();

    if (state.isDragging) {
      if (vaxisMouse.typeString === "drag") {
        const newOffset = {
          x: clayMouse.position.x - state.startPosition.x,
          y: clayMouse.position.y - state.startPosition.y,
        };
        updateDrag(newOffset);
      } else if (vaxisMouse.typeString === "release") {
        state.onDragEnd?.();
        endDrag();
      }
    }
  };

  const contextValue: DragContextType = {
    dragState,
    startDrag,
    updateDrag,
    endDrag,
    handleAreaMouse,
  };

  return (
    <DragContext.Provider value={contextValue}>
      {props.children}
    </DragContext.Provider>
  );
};

export const useDragContext = () => {
  const context = useContext(DragContext);

  return context;
};

export const useDraggable = (
  elementId: string,
  initialPosition: Vector2,
  initialSize: Vector2,
) => {
  const [position, setPosition] = createSignal(initialPosition);
  const [size, setSize] = createSignal(initialSize);
  var localState: "moving" | "resizing" | "none" = "none";
  const dragContext = useDragContext();

  const currentPosition = () => {
    const state = dragContext.dragState();
    if (
      state.isDragging &&
      state.draggedElementId === elementId &&
      localState == "moving"
    ) {
      return {
        x: position().x + state.currentOffset.x,
        y: position().y + state.currentOffset.y,
      };
    }
    return position();
  };

  const currentSize = () => {
    const state = dragContext.dragState();
    if (
      state.isDragging &&
      state.draggedElementId === elementId &&
      localState == "resizing"
    ) {
      return {
        x: size().x + state.currentOffset.x,
        y: size().y + state.currentOffset.y,
      };
    }
    return size();
  };

  const onDragEnd = () => {
    if (localState === "moving") {
      setPosition(currentPosition());
    } else if (localState === "resizing") {
      setSize(currentSize());
    }
  };

  const dragStart = (startPos: Vector2) => {
    dragContext.startDrag(elementId, startPos, onDragEnd);
  };

  const handleMouse: MouseEventHandler = (
    clayMouse,
    vaxisMouse,
    boundingBox,
  ) => {
    dragContext.handleAreaMouse(clayMouse, vaxisMouse, boundingBox);
    const state = dragContext.dragState();
    if (
      vaxisMouse.typeString === "press" &&
      vaxisMouse.buttonString === "left"
    ) {
      if (!state.isDragging) {
        log.info("mouse state", { state, vaxisMouse, boundingBox });
        if (boundingBox.y + 2 >= vaxisMouse.row) {
          localState = "moving";
          dragStart(clayMouse.position);
        } else if (
          boundingBox.x + boundingBox.width - 2 <= vaxisMouse.col &&
          boundingBox.y + boundingBox.height - 2 <= vaxisMouse.row
        ) {
          localState = "resizing";
          dragStart(clayMouse.position);
        }
      }
    }
  };

  return {
    position: currentPosition,
    size: currentSize,
    dragStart,
    handleMouse,
    isDragging: () => {
      const state = dragContext.dragState();
      return state.isDragging && state.draggedElementId === elementId;
    },
  };
};
