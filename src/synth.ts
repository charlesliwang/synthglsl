import * as Tone from 'tone';
  
  let preset_json = require('../resources/synth_presets/presets.json')

  var phaserA = new Tone.Phaser({
	"frequency" : 15,
	"octaves" : 5,
	"baseFrequency" : 1000
  }).toMaster();

  var distortionA = new Tone.Distortion(0.6)
  var autoWah = new Tone.AutoWah(100, 6, -30).toMaster();
  var crusher = new Tone.BitCrusher(8).toMaster();

class Synth {

    synth : any;
    phaser = phaserA;
    distortion = distortionA;
    synthName : string = "drums";
    constructor(synthName : string) {
      this.synthName = synthName;
      let synthB;
        if(this.synthName == "synthB") {
          synthB = new Tone.Synth(preset_json[synthName]).chain(crusher,autoWah,phaserA,distortionA)
        } else if (this.synthName == "drums") {
          synthB = new Tone.MembraneSynth();
        } else if (this.synthName == "cymbals") {
          synthB = new Tone.MetalSynth(preset_json[synthName]);
        }
        this.synth = synthB.toMaster()
    }

    startNote(note: string) {

        //play a middle 'C' for the duration
        if(this.synthName == "cymbals") {
          this.synth.triggerAttack();
        } else {
          this.synth.triggerAttack(note);
        }
    }
    endNote() {
        // Release note
        this.synth.triggerRelease();
    }

    
};

export default Synth;
