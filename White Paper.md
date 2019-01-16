> A white paper is a persuasive essay that uses facts and logic to promote a certain product, service, or viewpoint.

# Arduino Light Show

The intent of the project is to create an Arduino-centered setup, which converts audio input from multiple microphones into a corresponding visual output. 
The main use case for this setup would be to allow a band to have a (simple) live light show, without having to pre-program or use a click track. Optimally one would only have to place two or three microphones - specific to the Arduino - to pick up audio from different instruments. The audio signal captured by those microphones would then be used by the Arduino to control a remote LED-setup.

### Current Group

- Kevin Iatauro
- Karl Lund
- Marcus Rossel
- Trym Staurheim

---

### Hardware

-  [Arduino (probably UNO)](https://en.wikipedia.org/wiki/Arduino_Uno)

- [Microphones](https://www.amazon.de/Gaoxing-Tech-Empfindlichkeits-Mikrofon-Abfragungs/dp/B06XCKSKG1/ref=sr_1_2?ie=UTF8&qid=1547672642&sr=8-2&keywords=Arduino+Microphone)

-  [433MHz RF-transmitter](https://randomnerdtutorials.com/rf-433mhz-transmitter-receiver-module-with-arduino/)

-  [Remote controlled dimmable outlet](https://www.obi.de/hausfunksteuerung/home-easy-funk-steckdosendimmer-he878/p/6430334?wt_mc=gs.pla.Technik.SicherheitHaustechnik.Hausfunksteuerung&wt_cc1=664842664&wt_cc2=&wt_cc3=&wt_cc4=c&gclid=CjwKCAjw14rbBRB3EiwAKeoG_0SW0bwHGJlZ-U5C8u6usz1GWlYa5jHdXU04i18DXpQEug9Ly1enyRoCYvEQAvD_BwE)

- LED(s)

### External Libraries

-  [rc-switch](https://github.com/sui77/rc-switch.git)

---

### Rough Development Path

1. Hook up microphone to Arduino. ([Guide](https://www.instructables.com/id/Use-of-Microphone-Module/))

2. Hook up multiple microphones to Arduino.

3. Hook up RF-transmitter to Arduino. ([Guide](https://randomnerdtutorials.com/rf-433mhz-transmitter-receiver-module-with-arduino/))

4. Controll remote outlet with RF-transmitter.

5. Reverse engineer the protocol used by the remote outlet for dimming. ([Blog post](http://physudo.blogspot.com/2013/08/home-automation-mit-dem-arduino-und-433_17.html))

6. Write audio-to-RF converter.

###### If time allows for it:

7. Add some form of calibration interface to the converter (e.g. via Bash shell script).

8. Create a GUI that removes the need for command line interaction.

9. Allow the user to save different calibration-profiles.

###### About step 5:

Since most RF-transmitters are also receivers, we should just be able to send all of the different types of signals from the outlet's remote, and record their signature. Then we know what patterns we have to send, to simulate the remote.
