import * as Tone from 'tone';

var synthA = new Tone.Synth({
    oscillator: {
      type: 'fmsquare',
      modulationType: 'sawtooth',
      modulationIndex: 3,
      harmonicity: 3.4
    },
    envelope: {
      attack: 0.001,
      decay: 0.1,
      sustain: 0.1,
      release: 0.1
    }
  })
  
  var synthB = new Tone.Synth({
    oscillator: {
      type: 'triangle8'
    },
    envelope: {
      attack: 2,
      decay: 1,
      sustain: 0.4,
      release: 4
    }
  })

  var phaserA = new Tone.Phaser({
	"frequency" : 15,
	"octaves" : 5,
	"baseFrequency" : 1000
  }).toMaster();

  var distortionA = new Tone.Distortion(0.6)

class Synth {

    synth : any;
    phaser = phaserA;
    distortion = distortionA;
    constructor() {
        this.synth = synthB.chain(this.distortion, this.phaser).toMaster()
    }

    startNote() {

        //play a middle 'C' for the duration
        this.synth.add
        this.synth.triggerAttack("C4");
    }
    endNote() {
        // Release note
        this.synth.triggerRelease();
    }

    
};

export default Synth;
