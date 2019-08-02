import {vec2, vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import * as Tone from 'tone';
import Square from './geometry/Square';
import Mesh from './geometry/Mesh';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import {readTextFile} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Texture from './rendering/gl/Texture';

// Synth stuff
import Synth from './synth';
import { lookup } from 'dns';

// Define an object with application parameters and button callbacks
const controls = {
  'Pointalism' : false,
  'SSAO' : false,
  'Paint' : false,
  'Vaporwave' : true,
};

let postProcessActive : boolean[] = [true];

let square: Square;

// TODO: replace with your scene's stuff

let obj0: string;
let mesh0: Mesh;

let tex0: Texture;
let beatStart : number;


let synth0: Synth = new Synth("synthB");
let synthdrum: Synth = new Synth("drums");
let synthcymbal: Synth = new Synth("cymbals");
let drumdown = 0;
let drumkey : number;
let mouseX: number;
let mouseY: number;

let started = 0;

enum KeyBoard {
  SPACE = 32,
}

var timer = {
  deltaTime: 0.0,
  startTime: 0.0,
  currentTime: 0.0,
  updateTime: function() {
    var t = Date.now();
    t = (t - timer.startTime) * 0.001;
    timer.deltaTime = t - timer.currentTime;
    timer.currentTime = t;
  },
}

let baseBeat = [
  ["0:0", "C2"],
  ["0:0:1", "C2"], 
  ["0:0:2", "C2"], 
  ["0:0:3", "C2"], 
];
function toneStartup() {
  console.log("startup")
  var synth = new Tone.Synth().toMaster()
  // var pitchShift = new Tone.PitchShift(2).toMaster()
  // pitchShift.windowSize = 0.03;
  // synth.chain(pitchShift)

  var part = new Tone.Part(function(time:string, note:string){
    //the notes given as the second element in the array
    //will be passed in as the second argument
    beatStart = timer.currentTime;
    synth.triggerAttackRelease(note, "16n", time);
  }, baseBeat).start();
  part.loop = true; 
  part.loopEnd = '1m'
  Tone.Transport.start();
  Tone.Transport.bpm.value = 180;
}

function restartLoop() {
  Tone.Transport.stop()
  Tone.Transport.start()
}


function loadOBJText() {
  obj0 = readTextFile('./resources/obj/wahoo.obj')
}


function loadScene() {
  square && square.destroy();
  mesh0 && mesh0.destroy();

  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

  //mesh0 = new Mesh(obj0, vec3.fromValues(0, 0, 0));
  //mesh0.create();

  //tex0 = new Texture('./resources/textures/wahoo.bmp')
}


function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
    // Add controls to the gui
    const gui = new DAT.GUI();
    gui.add(controls, 'Pointalism' );
    gui.add(controls, 'Paint' );
    gui.add(controls, 'Vaporwave' );
    gui.add(controls, 'SSAO' );
    gui.closed = true;

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 9, 25), vec3.fromValues(0, 9, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0, 0, 0, 1);
  gl.enable(gl.DEPTH_TEST);

  const standardDeferred = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/standard-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/standard-frag.glsl')),
    ]);

  standardDeferred.setupTexUnits(["tex_Color"]);

  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    timer.updateTime();
    renderer.updateTime(timer.deltaTime, timer.currentTime);
    renderer.updateMousePos(vec2.fromValues(0,0), vec2.fromValues(mouseX/1000,mouseY/1000));
    renderer.updateBeat(timer.deltaTime, timer.currentTime - beatStart);

    //standardDeferred.bindTexToUnit("tex_Color", tex0, 0);

    renderer.clear();
    renderer.clearGB();

    renderer.postProcessesActive[4] = controls.Pointalism;
    renderer.postProcessesActive[3] = controls.Paint;
    renderer.postProcessesActive[2] = controls.Vaporwave;
    renderer.postProcessesActive[1] = controls.SSAO;

    // TODO: pass any arguments you may need for shader passes
    // forward render mesh info into gbuffers
    //renderer.renderToGBuffer(camera, standardDeferred, [mesh0]);
    // render from gbuffers into 32-bit color buffer
    renderer.renderFromGBuffer(camera);
    // apply 32-bit post and tonemap from 32-bit color to 8-bit color
    renderer.renderPostProcessHDR();
    // apply 8-bit post and draw
    renderer.renderPostProcessLDR();

    stats.end();
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  let notes = ["C","D","E","F","G","A","B"];
  window.addEventListener('mousedown', function(event) {
    if(started == 0) {
      started = 1;
      toneStartup();
    }
    mouseX = event.clientX;
    mouseY = window.innerHeight - event.clientY;
    let note : string = notes[Math.round(mouseX / 20 ) % notes.length]
    synth0.startNote(note + "4");
  }, false);
  window.addEventListener('mousemove', function(event) {
    mouseX = event.clientX;
    mouseY = window.innerHeight - event.clientY;
    synth0.phaser.frequency.value = mouseX/100;
    synth0.distortion.distortion = mouseY/400;
  }, false);
  window.addEventListener('mouseup', function(evnt) {
    synth0.endNote();
  }, false);
  window.addEventListener('keydown', function(event) {
    if (event.keyCode != drumkey) {
      drumdown = 0;
      drumkey = event.keyCode;
    } else if (event.keyCode == KeyBoard.SPACE) {
      restartLoop();
    }
    if(drumdown == 0) {
      if (drumkey == 13) {
        synthcymbal.startNote("");
      } else {
        synthdrum.startNote("C0");
      }
    }
    drumdown = 1;
  }, false);
  window.addEventListener('keyup', function(event) {
    synthdrum.endNote();
    drumdown = 0;
  }, false);
  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}


function setup() {
  timer.startTime = Date.now();
  loadOBJText();
  main();
}

setup();
