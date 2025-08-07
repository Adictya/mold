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
  startPosition: Vector2;
  currentOffset: Vector2;
};

type DragContextType = {
  dragState: () => DragState;
  startDrag: (elementId: string, startPos: Vector2) => void;
  updateDrag: (newOffset: Vector2) => void;
  endDrag: () => void;
	handleAreaMouse: MouseEventHandler;
};

const DragContext = createContext<DragContextType>();

export const DragProvider = (props: { children: any}) => {
  const [dragState, setDragState] = createSignal<DragState>({
    isDragging: false,
    draggedElementId: null,
    startPosition: { x: 0, y: 0 },
    currentOffset: { x: 0, y: 0 },
  });

  const startDrag = (elementId: string, startPos: Vector2) => {
    if (dragState().isDragging) return;

    setDragState({
      isDragging: true,
      draggedElementId: elementId,
      startPosition: startPos,
      currentOffset: { x: 0, y: 0 },
    });
  };

  const updateDrag = (newOffset: Vector2) => {
    if (!dragState().isDragging) return;

    setDragState(prev => ({
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

  const handleAreaMouse: MouseEventHandler = (clayMouse, vaxisMouse, boundingBox) => {
    const state = dragState();

    if (state.isDragging) {
      if (vaxisMouse.typeString === "drag") {
        const newOffset = {
          x: clayMouse.position.x - state.startPosition.x,
          y: clayMouse.position.y - state.startPosition.y,
        };
        updateDrag(newOffset);
      } else if (vaxisMouse.typeString === "release") {
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
  if (!context) {
    throw new Error("useDragContext must be used within a DragProvider");
  }
  return context;
};

export const useDraggable = (elementId: string, initialPosition: Vector2) => {
  const [position, setPosition] = createSignal(initialPosition);
  const dragContext = useDragContext();

  const dragStart = (startPos: Vector2) => {
    dragContext.startDrag(elementId, startPos);
  };

  const handleMouse: MouseEventHandler = (clayMouse, vaxisMouse, boundingBox) => {
    if (vaxisMouse.typeString === "press" && vaxisMouse.buttonString === "left") {
      dragStart(clayMouse.position);
    } else if (vaxisMouse.typeString === "release") {
      const state = dragContext.dragState();
      if (state.isDragging && state.draggedElementId === elementId) {
        // Update the base position to include the final offset
        setPosition({
          x: position().x + state.currentOffset.x,
          y: position().y + state.currentOffset.y,
        });
      }
      dragContext.endDrag();
    }
    dragContext.handleAreaMouse(clayMouse, vaxisMouse, boundingBox);
  };

  const currentPosition = () => {
    const state = dragContext.dragState();
    if (state.isDragging && state.draggedElementId === elementId) {
      return {
        x: position().x + state.currentOffset.x,
        y: position().y + state.currentOffset.y,
      };
    }
    return position();
  };

  const updatePosition = (newPos: Vector2) => {
    setPosition(newPos);
    const state = dragContext.dragState();
    if (state.isDragging && state.draggedElementId === elementId) {
      dragContext.endDrag();
    }
  };

  return {
    position: currentPosition,
    setPosition: updatePosition,
    dragStart,
    handleMouse,
    isDragging: () => {
      const state = dragContext.dragState();
      return state.isDragging && state.draggedElementId === elementId;
    },
  };
};
