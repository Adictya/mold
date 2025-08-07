import MoldCore from './core';
export {log} from './logging';

if (import.meta.hot) {
  import.meta.hot.dispose((data) => {
		console.info("onDispose index");
  });
}

export * from './solid';
export * from './components';
export * from './drag';
export default MoldCore;
