const MoldCore = require('./native/mold_native.node');

export default function hello() {
  console.log(MoldCore.init(2));
}
