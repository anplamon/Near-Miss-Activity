package {
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.ui.Mouse;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextField;
    import flash.text.TextFormat
	import flash.net.*;
	import flash.utils.Timer;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.filters.*;
	
	public class GameController extends MovieClip {
		/***************************************************************************************************************************/
		private var WDisp:Number = 80; // GameStage Displacement to the middle of the stage
		private var HDisp:Number = 42; // GameStage Displacement to the middle of the stage
		private var safetyNum:Number = 12; //Number of Safety Hazards. Max=24
		private var extraNum:Number = 2; //Extra guys. Max = 24-safetyNum
		private var boxVisible:Number = 0; // If 1 the boxes are visible, else the boxes are invisible.
		
		//Location of all Safety Hazards from top to bottom
		private var safetyLocations:Array = new Array(new Array(228,170),  new Array(230,430),new Array(280,610), new Array(140,480),
													  new Array(470,589), new Array(420,617), new Array(260,460), new Array(30,550),
													  new Array(90,530), new Array(300,579), new Array(149,350), new Array(110,360));
													
		//Safety Boxes
		private var safetyBoxes:Array = new Array(new wireBox, new metalBox, new bagBox,  new tagBox, new plankBox, new ropeBox,
												  new shovelBox, new barrelBox, new hatBox, new barrierBox, new stairBox, new guyBox);
												  
		//Safety messages corresponding to the safety hazards above			  
		private var safetyMsg:Array = new Array(new String("The rope is too close to\nthe edge and there is no\ntoe board."),
												new String("A piece of channel iron\nis on the staircase."),
												new String("Plastic bag should not\nbe left lying on the\nground. It should be\nplaced in the plastic\nonly barrel."),
												new String("There is no tag on the\nscaffold."),
												new String("The plank on the\nscaffold is creating a\ntripping hazard."),
												new String("The rope should not be\nleft lying on the ground."),
												new String("Fire extinguisher and\nshovel are on the\nstaircase."),
												new String("The plastic only barrel\nhas wood in it."),
												new String("The hardhat should be\non someones head!"),
												new String("No guarding under the\nchute."),
												new String("The stair is missing."),
												new String("The person here is\nmissing some of his\nPPE. He is missing his\nhardhat,safety glasses\nand his highvis."));
		
		/***************************************************************************************************************************/
		
		//Background
		private var mcGameStage:GameStage = new GameStage(); //All objects will be placed on this.
		private var statGameStage:GameStage = new GameStage(); //Strictly used for stats
		private var statsGameStage = new GameStage(); //Statistics will be displayed here
		private var img:safetyImage = new safetyImage(); // Image chosen
		private var greenShadow:DropShadowFilter = new DropShadowFilter(); // Green drop shadow for corrent answers
		private var redShadow:DropShadowFilter = new DropShadowFilter(); // Red drop shadow for wrong answers.

		//Sound
		private var typeSound:Sound = new typewriterSound();//typing sound
		private var channel:SoundChannel = new SoundChannel();//Plays all of the sounds
		private var soundTimer:Timer = new Timer(1700, 1)//Stops the last ding on the typewriter sound effect
	
		//Safety Man
		private var boxArray:Array = new Array(); //Array of unfounf check boxes
		private var safeMan:man = new man(); // Current static man. Used to display the safety message.
		private var safetyMan:man = new man(); // Strictly used for stats
		private var Man:Object; //Current man
		private var manCheck:Array = new Array(); //Checks to see if the man has been placed
		private var manArray:Array = new Array(new man,new man,new man,new man,new man,new man,new man,new man,
											   new man,new man,new man,new man,new man,new man,new man,new man,
											   new man,new man,new man,new man,new man,new man,new man,new man);
											   
		//Sign
		private var maskBox:textBox; // Mask for the safety message text
		private var txtBox:textBox;	// Box for safety message text
		private var endTxtBox:endTextBox = new endTextBox(); // Notification Box for the last man in the stack of men
		private var redX:redCross = new redCross(); // Incorrect Symbol that will be flashed
		private var redXArray:Array = new Array(); //Contains redX's That are currently Flashing.
		private var typeArray:Array = new Array(); //Check to see if a sign is typing or not
		private var zoomTime:Number = 400; //Amount of time the box will zoom in or out.
		private var typeTime:Number = 30; //Amount of time it will take to type out each letter.
		private var zoomInterval:Number = 20; //Number of intervals the zoom time will be broken down in.
		private var zoomScale:Number = 5; // How large the message box will be zoomed
		private var zoomScaleInterval:Number = zoomScale/zoomInterval //Time for each zoom interval
		private var zoomInProgress:Boolean = false; // //True if a sign is zooming in or out to only allow one to zoom at a time.
		private var safeManArray:Array = new Array(); // Array of all safe men.
		
		//Buttons
		private var DoneBTN:doneBTN = new doneBTN();
		private var EraseBTN:eraseBTN = new eraseBTN();
		private var MagnifyBTN:magnifyBTN = new magnifyBTN();
		private var plyBTN:playBTN = new playBTN;
		private var menuHeight:Number = safetyMan.height+7;
		private var menuWidth:Number = 150;

		//Magnify
		private var imgLarge:Sprite = new Sprite(); //Magnified image
		private var scale:Number = 2; //How large the image will be (ie. X times as large)
		private var radius:Number = 75; //Radius of the magnified circle
		private var isMagnified:Boolean = false; //Is the magnification tool on or not
		
		private function initializeMenu() {
			// Draw menu box
			var menuBox:MovieClip = new MovieClip();
			menuBox.graphics.beginFill(0xFFFFFF);
			menuBox.graphics.drawRect(0, 0, menuWidth, menuHeight);
			menuBox.graphics.endFill();
			mcGameStage.addChild(menuBox);
			
			// Draws the circle at the end
			var menuCirc:MovieClip = new MovieClip();
			menuCirc.graphics.beginFill(0xFFFFFF);
			menuCirc.graphics.drawCircle(menuWidth, menuHeight/2, menuHeight/2);
			menuCirc.graphics.endFill();
			mcGameStage.addChild(menuCirc);
			
			// Draws Menu Dividers
			var menuDiv:MovieClip = new MovieClip();
			menuDiv.graphics.beginFill(0x000000);
			menuDiv.graphics.drawRect(49, 4, 2, menuHeight-8);
			menuDiv.graphics.drawRect(102, 4, 2, menuHeight-8);
			menuDiv.graphics.endFill();
			mcGameStage.addChild(menuDiv);
			
			buttonListeners(true);//Activates the Done and Erase Button
			
			//Place Magnify Button
			mcGameStage.addChild(MagnifyBTN);
			MagnifyBTN.x = 63;
			MagnifyBTN.y = 7;
			
			//Button Functionality
			MagnifyBTN.addEventListener(MouseEvent.CLICK, magn);
			function magn(event:MouseEvent):void {
				MagnifyBTN.removeEventListener(MouseEvent.CLICK, magn);
				MagnifyBTN.addEventListener(MouseEvent.CLICK, unMagn);
				magnify(true);
			}
				
			function unMagn(event:MouseEvent):void {
				MagnifyBTN.removeEventListener(MouseEvent.CLICK, unMagn);
				MagnifyBTN.addEventListener(MouseEvent.CLICK, magn);
				magnify(false);
			}
				
			//Control click functionality
			mcGameStage.addEventListener(MouseEvent.CLICK, zoom);
			function zoom(event:MouseEvent):void {
				if (!event.ctrlKey) return;
				if (!isMagnified) {
					magnify(true);
					MagnifyBTN.removeEventListener(MouseEvent.CLICK, magn);
					MagnifyBTN.addEventListener(MouseEvent.CLICK, unMagn);
				}
				else {
					MagnifyBTN.removeEventListener(MouseEvent.CLICK, unMagn);
					MagnifyBTN.addEventListener(MouseEvent.CLICK, magn);
					magnify(false);
				}
			}
			
			//Places the check boxes
			for (var j=0;j<safetyBoxes.length;j++) {
				if (safetyBoxes[j] != null) {
					var box = safetyBoxes[j];
					mcGameStage.addChild(box);
					box.x = safetyLocations[j][0];
					box.y = safetyLocations[j][1];
					box.alpha = boxVisible;
					boxArray[j] = box;
				}
			}
			
			//Places the Last Man
			var endMan:man = new man();
			endMan.x = 5;
			endMan.y = 5;
			mcGameStage.addChild(endMan);
			
			// Places Last Mans Text Box;
			endTxtBox.x = endMan.x+17.5;
			endTxtBox.y = endMan.y+11.65;
			mcGameStage.addChild(endTxtBox);
			
			// Places and initializes the men
			for (var i=0;i<safetyNum+extraNum;i++) {
				manCheck[i] = 1;
			}
			manPlace(); // Places all of the mans
			
			//Creates the green drop shadow
			greenShadow.distance = 0;
			greenShadow.color = 0x00FF00;
			greenShadow.blurX = 10;
			greenShadow.blurY = 10;
			greenShadow.quality = 3;
			
			//Creates the red drop shadow
			redShadow.distance = 0;
			redShadow.color = 0xFF0000;
			redShadow.blurX = 10;
			redShadow.blurY = 10;
			redShadow.quality = 3;

		}
	
		private function buttonListeners(Check:Boolean) {
			//Activates or Deactivates the Done and Erase Button
			if (DoneBTN.parent == mcGameStage) mcGameStage.removeChild(DoneBTN);
			if (EraseBTN.parent == mcGameStage) mcGameStage.removeChild(EraseBTN);
			DoneBTN = new doneBTN()
			EraseBTN = new eraseBTN()
			
			if (Check) {
				//Place DONE button
				mcGameStage.addChild(DoneBTN);
				DoneBTN.x = 112;
				DoneBTN.y = menuHeight/2-DoneBTN.height/2-1;
			
				if (safetyNum != 0) {
					DoneBTN.addEventListener(MouseEvent.CLICK, end);
					function end(event:MouseEvent):void {
						/*mcGameStage.removeChild(EraseBTN);
						EraseBTN = new eraseBTN;
						mcGameStage.addChild(EraseBTN);
						EraseBTN.x = 52;
						EraseBTN.y = 45;*/
						
						DoneBTN.removeEventListener(MouseEvent.CLICK, end);
						/*MagnifyBTN.removeEventListener(MouseEvent.CLICK, magn);
						MagnifyBTN.removeEventListener(MouseEvent.CLICK, unMagn);
						mcGameStage.removeEventListener(MouseEvent.CLICK, zoom);*/
						
						// Removes any flahing X's
						for (var k=0;k<redXArray.length;k++) {
							mcGameStage.removeChild(redXArray[k]);
						}
						
						manCheck = new Array(0);
						redXArray = new Array();
						if (isMagnified) magnify(false);
						endGame();
					}
				}
				
				//Place Erase button
				mcGameStage.addChild(EraseBTN);
				EraseBTN.x = 52;
				EraseBTN.y = 45;

				EraseBTN.addEventListener(MouseEvent.CLICK, reset);
				function reset(event:MouseEvent):void {
					// Removes any flahing X's
					for (var k=0;k<redXArray.length;k++) {
						mcGameStage.removeChild(redXArray[k]);
					}
					
					//Removes all safety men from the stage
					for (var n=0;n<manArray.length;n++) {
						if (manArray[n].parent == mcGameStage) {
							mcGameStage.removeChild(manArray[n]);
							manArray[n] = new man();
						}
					}
					
					for (var a=0;a<safetyNum+extraNum;a++) {
						manCheck[a] = 1;
					}
	
					//Adds the safe men Back to the stage with unzoomed boxes.
					for (var m=0;m<safeManArray.length;m++) {
						var tempMan = safeManArray[m][0]
						safeMan = new man();
						mcGameStage.removeChild(tempMan);
						mcGameStage.addChild(safeMan);
						safeMan.x = tempMan.x
						safeMan.y = tempMan.y
						
						txtBox = new textBox();
						txtBox.x = 17.5;
						txtBox.y = 11.65;
						txtBox.buttonMode = true;
						safeMan.addChild(txtBox);
								
						safeMan['Msg'] = safeManArray[m][1];
						safeMan['typed'] = true;
						safeMan['textBox'] = txtBox;
						safeMan['correct'] = tempMan['correct'];
						
						initializeMsg(safeMan);
						zoomInEnable(safeMan);
						simulatedScale();
						
						safeMan.addChildAt(safeMan['txtMask'],safeMan.getChildIndex(safeMan['textBox'])+1);
						safeMan.addChildAt(safeMan['txt'],safeMan.getChildIndex(safeMan['txtMask']));
						
						if (safeMan['correct'] == true) safeMan.filters = [greenShadow];
						else if (safeMan['correct'] == false) safeMan.filters = [redShadow];
						safeManArray[m] = new Array(safeMan,safeMan['Msg']);
					}
					
					channel.stop();
					redXArray = new Array();
					manPlace();
				}
			}
			else {
				//Place DONE button
				mcGameStage.addChild(DoneBTN);
				DoneBTN.x = 112;
				DoneBTN.y = menuHeight/2-DoneBTN.height/2-1;
				
				//Place Erase button
				mcGameStage.addChild(EraseBTN);
				EraseBTN.x = 52;
				EraseBTN.y = 45;
			}
		}
	
		private function magnify(magnifyCheck:Boolean) {
			// Creates a magnified version of the image
			if (magnifyCheck == true) {
				isMagnified = true;
				imgLarge = new safetyImage();
				imgLarge.scaleX = scale;
				imgLarge.scaleY = scale;
				mcGameStage.addChildAt(imgLarge,2);
			
				// Draws circular mask
				var boardMask:Shape=new Shape();
				boardMask.graphics.beginFill(0xDDDDDD);
				boardMask.graphics.drawCircle(0,0, radius);
				boardMask.graphics.endFill();
				mcGameStage.addChildAt(boardMask,3);
				boardMask.x = mcGameStage.mouseX;
				boardMask.y = mcGameStage.mouseY;
				imgLarge.mask = boardMask;
				
				//Initialize the large image position
				if (boardMask.x >= mcGameStage.width/2) imgLarge.x = mouseX*scale/2-WDisp;
				if (boardMask.x < mcGameStage.width/2) imgLarge.x = mouseX*-scale/2+WDisp;
				if (boardMask.y >= mcGameStage.height/2) imgLarge.y = mouseY*scale/2-HDisp;
				if (boardMask.y < mcGameStage.height/2) imgLarge.y = mouseY*-scale/2+HDisp;
			
				//Update the magnification tool
				mcGameStage.addEventListener(MouseEvent.MOUSE_MOVE, magnifyMove);
				function magnifyMove(event:MouseEvent):void {
					boardMask.x = mouseX-WDisp;
					boardMask.y = mouseY-HDisp;;
					
					if (boardMask.x >= mcGameStage.width/2) imgLarge.x = mouseX*scale/2-WDisp;
					if (boardMask.x < mcGameStage.width/2) imgLarge.x = mouseX*-scale/2+WDisp;
					if (boardMask.y >= mcGameStage.height/2) imgLarge.y = mouseY*scale/2-HDisp;
					if (boardMask.y < mcGameStage.height/2) imgLarge.y = mouseY*-scale/2+HDisp;
				}
			}
			else {
				//Turns off the magnification tool by removing it.
				isMagnified = false;
				mcGameStage.removeChild(imgLarge);
			}
		}
	
		private function manPlace() {
			// Place the safety men
			for (var j=manCheck.length-1;j>=0;j--) {
				if (manCheck[j] == 1) {
					manCheck[j] = 0;
					mcGameStage.addChild(manArray[j]);
					manArray[j].x = 5;
					manArray[j].y = 5;
					manArray[j]['flash'] = false;
					manArray[j].buttonMode = true;
						
					manArray[j].addEventListener(MouseEvent.MOUSE_DOWN, startMove);
					manArray[j].addEventListener(MouseEvent.MOUSE_UP, stopMove);
						
					function startMove(a:MouseEvent):void {
						//Initializes the move
						Man = a.currentTarget;
						Mouse.hide();
						stage.addEventListener(MouseEvent.MOUSE_MOVE, manMove);
					} 

 					function manMove(b:MouseEvent):void {
						//Moves the man
						var indexman:Number = manArray.indexOf(Man);
						
						//Keeps the man in the stage
						Man.x = goodX(mouseX)-(Man.width/2)-WDisp; 
						Man.y = goodY(mouseY)-(Man.height/2)-HDisp;
							
						//Move the flashing cross with the Man if it is flashing;
						if (Man['flash']) {
							Man['redX'].x = Man.x+9.95;
							Man['redX'].y = Man.y+3.8
						}
							
						b.updateAfterEvent();
					}
						
					function stopMove(c:MouseEvent):void { 
						//Removes the move listener.
						Man = c.currentTarget;
						for(var i=0;i<safetyBoxes.length;i++) {
							if ((safetyBoxes[i] != null) && (Man.hitTestObject(safetyBoxes[i]))) {
								//If there was a collision, then converts a Man to a Static safeMan
								staticMan(safetyMsg[i]);
								mcGameStage.removeChild(safetyBoxes[i]);
								safetyBoxes.splice(i,1,null);
								break;
							}
						}
						
						if ((i==safetyBoxes.length) && (!Man['flash'])) {
							//If there was not a collision, display incorrect X							
							Man['flash'] = true
							redX = new redCross();
							redX.x = Man.x+9.95;
							redX.y = Man.y+3.8
							redX.alpha = 0;
							Man['redX'] = redX
							redXArray.push(Man['redX']);
							mcGameStage.addChildAt(Man['redX'],mcGameStage.getChildIndex(MovieClip(Man))+1);
							flashXOn(MovieClip(Man));
						}
							
						Mouse.show();
						stage.removeEventListener(MouseEvent.MOUSE_MOVE, manMove); 
					}
						
					function staticMan(msg:String) {
						//Converts the Man into a static man and types the safety message
						safeMan = new man();
						mcGameStage.addChild(safeMan);
						safeMan.x = Man.x;
						safeMan.y = Man.y;
						
						safetyNum--;
						buttonListeners(false);//Deactivates the DONE and Erase Button
						typeArray.push('Shazam');//Indicates that the message is being typed;
						
						//Text Box to hold the safety message
						txtBox = new textBox();
						txtBox.x = 17.5;
						txtBox.y = 11.65;
						txtBox.buttonMode = true;
						safeMan.addChild(txtBox);
						
						//Initialize properties of the safeMan
						safeMan['Msg'] = msg; //Message corresponing to his location
						safeMan['typed'] = false; //ShowsIf the message has been typed out
						safeMan['textBox'] = txtBox; //safeMans personal text box
						safeMan['correct'] = 'Shazam'; // This will determine what glow the safeMan will get if he was correct
						initializeMsg(safeMan);
						safeManArray.push(new Array(safeMan,msg));
						zoomIn(safeMan);
							
						if (safetyNum == 0) winScreen(); //If all of the safety hazards have been found, goto winScreen
					}
				}
			}
		}
		
		private function zoomIn(safeMan:MovieClip) {
			// Enlarges the textBox and the safety message
			zoomInProgress = true;
			mcGameStage.addChildAt(safeMan,mcGameStage.numChildren);
			
			var timer:Timer = new Timer(zoomTime/zoomInterval, zoomInterval);
			timer.addEventListener(TimerEvent.TIMER, zoom);
			
			var typeTimer:Timer = new Timer(zoomTime+200, 1);
			typeTimer.addEventListener(TimerEvent.TIMER, type);
			
			timer.start();
			typeTimer.start();
			zoomScale = 1;
			
			function zoom(e:TimerEvent):void {
				zoomScale += zoomScaleInterval
				
				safeMan['textBox'].scaleX = zoomScale;
				safeMan['textBox'].scaleY = zoomScale;
				safeMan['textBox'].x = 17.5;
				safeMan['textBox'].y = 11.65;
				
				safeMan['txtMask'].scaleX = zoomScale;
				safeMan['txtMask'].scaleY = zoomScale;
				safeMan['txtMask'].x = 17.5;
				safeMan['txtMask'].y = 11.65;
				
				safeMan['txt'].scaleX = zoomScale;
				safeMan['txt'].scaleY = zoomScale;
				safeMan['txt'].x = safeMan['textBox'].x-safeMan['textBox'].width/2; 
				safeMan['txt'].y = safeMan['textBox'].y-safeMan['textBox'].height/2+((5-safeMan['txt'].numLines)*((safeMan['textBox'].height/5)/2))-10;
			}
			
			function type(e:TimerEvent):void {
				zoomInProgress = false;
				if (!safeMan['typed']) {
					//If the message has not been typed out, then type it out.
					safeMan['typed'] = true;
					typeMsg(safeMan);
				}
				else zoomOutEnable(safeMan);
			}
		}
		
		
		private function zoomOut(safeMan:MovieClip) {
			// Shrinks the textBox and the safety message
			zoomInProgress = true;
			var timer:Timer = new Timer(zoomTime/zoomInterval, zoomInterval);
			timer.addEventListener(TimerEvent.TIMER, zoom);
			
			var typeTimer:Timer = new Timer(zoomTime+200, 1);
			typeTimer.addEventListener(TimerEvent.TIMER, type);
			
			typeTimer.start();
			timer.start();
			zoomScale = 6;
			
			function zoom(e:TimerEvent):void {
				zoomScale -= zoomScaleInterval
				
				safeMan['textBox'].scaleX = zoomScale;
				safeMan['textBox'].scaleY = zoomScale;
				safeMan['textBox'].x = 17.5;
				safeMan['textBox'].y = 11.65;
				
				safeMan['txtMask'].scaleX = zoomScale;
				safeMan['txtMask'].scaleY = zoomScale;
				safeMan['txtMask'].x = 17.5;
				safeMan['txtMask'].y = 11.65;
				
				safeMan['txt'].scaleX = zoomScale;
				safeMan['txt'].scaleY = zoomScale;
				safeMan['txt'].x = safeMan['textBox'].x-safeMan['textBox'].width/2; 
				safeMan['txt'].y = safeMan['textBox'].y-safeMan['textBox'].height/2+((5-safeMan['txt'].numLines)*((safeMan['textBox'].height/5)/2))-10;
			}
			
			function type(e:TimerEvent):void {
				zoomInProgress = false;
				zoomInEnable(safeMan);
			}
		}
		
		
		private function initializeMsg(safeMan:MovieClip) {
			// Initialize the safety message
			var txtFormat:TextFormat = new TextFormat();
			txtFormat.size = 3;
			txtFormat.align = 'center';

			// Safety Message
			var txt:TextField = new TextField();
			txt.defaultTextFormat = txtFormat;
			txt.width = 32.65;
			txt.height = 20;
			txt.x = safeMan['textBox'].x-safeMan['textBox'].width/2;
			txt.y = safeMan['textBox'].y-safeMan['textBox'].height/2;
			txt.text = safeMan['Msg'];
			txt.mouseEnabled = false;
			
			// Safety Message Mask
			maskBox = new textBox();
			maskBox.x = safeMan.x+17.5;
			maskBox.y = safeMan.y+11.65;
			txt.mask = maskBox;
			
			safeMan['txt'] = txt; //safeMans initialized text
			safeMan['txtMask'] = maskBox; //safeMans initialized text mask
		}
		
		private function typeMsg(safeMan:MovieClip) {
			//Type the safety message out like a type writer.
			var txtFormat:TextFormat = new TextFormat();
			txtFormat.size = 17.5;
			txtFormat.align = 'center';
			
			var txtType:TextField = new TextField();
			txtType.defaultTextFormat = txtFormat;
			txtType.width = safeMan['txt'].width;
			txtType.height = safeMan['txt'].height-((5-safeMan['txt'].numLines)*((safeMan['textBox'].height/5)/2));
			txtType.x = safeMan['textBox'].x-safeMan['textBox'].width/2;
			txtType.y = safeMan['textBox'].y-safeMan['textBox'].height/2+((5-safeMan['txt'].numLines)*((safeMan['textBox'].height/5)/2));
			txtType.mouseEnabled = false;

			safeMan.addChildAt(txtType,safeMan.getChildIndex(safeMan['textBox'])+1);
			safeMan['txtType'] = txtType;
			
			var charNum:Number = safeMan['Msg'].length;
			var counter:Number = 0;
			
			var timer:Timer = new Timer(typeTime, charNum+1);
			timer.addEventListener(TimerEvent.TIMER, type);
		     
			//Plays sound typing sound effect
			channel.stop();
			soundTimer.stop();
			var transform:SoundTransform = channel.soundTransform;
			transform.volume = 0.2;
			channel = typeSound.play(1800);
			channel.soundTransform = transform;
			timer.start();
			
			function type(e:TimerEvent):void {
				if (counter != charNum) {
					//Type out one letter
					var char:String = safeMan['Msg'].slice(counter,counter+1)
					safeMan['txtType'].text += char;
					counter++;
				}
				else {
					// Playes final ding
					channel.stop();
					var transform:SoundTransform = channel.soundTransform;
					transform.volume = 0.2;
					channel = typeSound.play(30000);
					channel.soundTransform = transform;
					
					soundTimer = new Timer(1700, 1);
					soundTimer.addEventListener(TimerEvent.TIMER, endSound);
					soundTimer.start();
					function endSound(e:TimerEvent):void {
						channel.stop();
					}
					
					//Places a zoomable text and the text mask
					safeMan['txt'].height = (safeMan['txt'].height-((5-safeMan['txt'].numLines)*((safeMan['textBox'].height/5)/2)))*0.2;
					safeMan.addChildAt(safeMan['txt'],safeMan.getChildIndex(safeMan['txtType']))
					safeMan.addChildAt(safeMan['txtMask'],safeMan.getChildIndex(safeMan['txt'])+1)
					safeMan.removeChild(safeMan['txtType'])
					zoomOutEnable(safeMan);
					
					//Activates the DONE and Erase Button if there is no other sign typing
					typeArray.pop();
					if (typeArray.length == 0) buttonListeners(true);
				}
							
			}
		}
		
		private function zoomOutEnable(safeMan:MovieClip) {
			//Enable the text box to shrink if clicked
			safeMan.addEventListener(MouseEvent.CLICK ,callZoomOut);
			safeMan['textBox'].addEventListener(MouseEvent.CLICK ,callZoomOut2);
			safeMan.buttonMode = true;
			
			function callZoomOut(e:MouseEvent):void {
				//function for the safe man
				var sMan = e.currentTarget;
				if (!zoomInProgress) {
					zoomOut(sMan);
					sMan.removeEventListener(MouseEvent.CLICK ,callZoomOut);
					sMan['textBox'].removeEventListener(MouseEvent.CLICK ,callZoomOut2);
				}
			}
			
			function callZoomOut2(e:MouseEvent):void {
				//function for the text box
				var sMan = e.currentTarget;
				if (!zoomInProgress) {
					zoomOut(sMan.parent);
					sMan.parent.removeEventListener(MouseEvent.CLICK ,callZoomOut);
					sMan.removeEventListener(MouseEvent.CLICK ,callZoomOut2);
				}	
			}
		}
		
		private function zoomInEnable(safeMan:MovieClip) {
			//Enable the text box to enlarge if clicked
			safeMan.addEventListener(MouseEvent.CLICK ,callZoomIn);
			safeMan['textBox'].addEventListener(MouseEvent.CLICK ,callZoomIn2);
			safeMan.buttonMode = true;
			
			function callZoomIn(e:MouseEvent):void {
				//function for the safe man
				var sMan = e.currentTarget;
				if (!zoomInProgress) {
					zoomIn(sMan);
					sMan.removeEventListener(MouseEvent.CLICK ,callZoomIn);
					sMan['textBox'].removeEventListener(MouseEvent.CLICK ,callZoomIn2);
				}
			}
			
			function callZoomIn2(e:MouseEvent):void {
				//function for the safe man
				var sMan = e.currentTarget;
				if (!zoomInProgress) {
					zoomIn(sMan.parent);
					sMan.parent.removeEventListener(MouseEvent.CLICK ,callZoomIn);
					sMan.removeEventListener(MouseEvent.CLICK ,callZoomIn2);
				}
			}
		}
		
		private function flashXOn(flashMan:MovieClip) {
			//Begins the flashing X
			flashMan['redX'].x = flashMan.x+9.95;
			flashMan['redX'].y = flashMan.y+3.8
			flashMan['redX'].alpha = 1;
				
			var timer1:Timer = new Timer(500, 1);
			timer1.addEventListener(TimerEvent.TIMER, flashOff);
			timer1.start();
				
			function flashOff(e:TimerEvent):void {
				flash1(flashMan);
			}
		}
		
		private function flash1(flashMan:MovieClip) {
			flashMan['redX'].alpha = 0;
					
			var timer2:Timer = new Timer(500, 1);
			timer2.addEventListener(TimerEvent.TIMER, flashOn);
			timer2.start();
			function flashOn(e:TimerEvent):void {
					flash2(flashMan);
			}
		}
		
		private function flash2(flashMan:MovieClip) {
			flashMan['redX'].x = flashMan.x+9.95;
			flashMan['redX'].y = flashMan.y+3.8
			flashMan['redX'].alpha = 1;
			
			var timer3:Timer = new Timer(500, 1);
			timer3.addEventListener(TimerEvent.TIMER, flashingOff);
			timer3.start();
			function flashingOff(e:TimerEvent):void {
					flash3(flashMan);
			}
		}
		
		private function flash3(flashMan:MovieClip) {
			//Remove the rexX from the list of current flashing X's and removes it from the stage
			if (flashMan['redX'].parent == mcGameStage) {
				redXArray.reverse();
				redXArray.pop();
				redXArray..reverse();
				mcGameStage.removeChild(flashMan['redX']);
			}
			flashMan['flash'] = false;
		}

		private function goodX(intX:Number):Number {
			//Ensures the man stays within the stage.
			if (intX < safetyMan.width/2+WDisp) return safetyMan.width/2+WDisp;
			if (intX > statGameStage.width-safetyMan.width/2+WDisp) return statGameStage.width-safetyMan.width/2+WDisp;
			return intX
		}
		
		private function goodY(intY:Number):Number {
			//Ensures the man stays within the stage.
			if (intY < safetyMan.height/2+HDisp) return safetyMan.height/2+HDisp;
			if (intY > statGameStage.height-safetyMan.height/2+HDisp) return statGameStage.height-safetyMan.height/2+HDisp;
			return intY
		}
		
		private function drawImg(Alpha:Number) {
			// Place the image in the centre of the mcGameStage
			mcGameStage = new GameStage();
			stage.addChild(mcGameStage);
			mcGameStage.x = WDisp;
			mcGameStage.y = HDisp;
			mcGameStage.addChild(img);
			img.alpha = Alpha
		}
		
		private function instructions() {
			// Text Header format
			var txtFormat:TextFormat = new TextFormat();
			txtFormat.size = 40;

			// Header
			var txtH:TextField = new TextField();
			txtH.autoSize = TextFieldAutoSize.CENTER;
			txtH.defaultTextFormat = txtFormat;
			txtH.textColor = 0xFF0000;
			txtH.x = (mcGameStage.width /2) - (txtH.textWidth/2);
			txtH.y = 20;
			txtH.text = "Instructions"
			
			// Text SubHeader Format
			txtFormat.size = 20;
			txtFormat.align = "center";
			
			// SubHeader
			var txtSH:TextField = new TextField();
			txtSH.autoSize = TextFieldAutoSize.CENTER;
			txtSH.defaultTextFormat = txtFormat;
			txtSH.width = mcGameStage.width *.8;
			txtSH.text = "This photo has been staged to show a number of safety hazards and dangerous work habits. See how many you can find!";
			txtSH.wordWrap = true;
			txtSH.x = (mcGameStage.width /2) - (txtSH.textWidth/2);
			txtSH.y = txtH.y + txtH.textHeight*1.5;
			
			// Text Body Format
			txtFormat.size = 20;
			txtFormat.align = "left";
			
			// Body
			var str1:String = "1.  Drag the Safety Man located in the top left-hand corner of the photo to wherever you see dangerous work habits or housekeeping issues.";
			var str2:String = "2.  Keep placing the Safety Man until you have identified all the hazards you can see. You can remove extra Safety Men or close the answer boxes by clicking the eraser at the corner.";
			var str3:String = "3.  If you have trouble seeing the picture, click on the magnifying glass in the top left corner of hold the control key and click.";
			var str4:String = "4.  When you have finished, click DONE in the top left-hand corner of the photo.";
			var str5:String = "5.  Once you have clicked on the DONE button, the answers will be displayed. You can click on each one to see what was unsafe about it and to see how many people have found that safety violation.";
			
			var txtB:TextField = new TextField();
			txtB.autoSize = TextFieldAutoSize.LEFT;
			txtB.defaultTextFormat = txtFormat;
			txtB.width = mcGameStage.width *.9;
			txtB.text = str1 + "\n" + str2 + "\n" + str3 + "\n" + str4 + "\n" + str5;
			txtB.wordWrap = true;
			txtB.x = (mcGameStage.width /2) - (txtB.textWidth/2);
			txtB.y = txtSH.y + txtSH.textHeight*1.5;
			
			//White Background box to increase readablilty
			var bgBox:MovieClip = new MovieClip();
			bgBox.graphics.beginFill(0xFFFFFF);
			bgBox.graphics.drawRect(txtB.x-5, txtH.y-5, txtB.width+10, txtB.height+txtH.height*1.5+txtSH.height*1.5 +10);
			bgBox.graphics.endFill();
			
			//Adds all above to stage
			mcGameStage.addChild(bgBox);
			mcGameStage.addChild(txtH);
			mcGameStage.addChild(txtSH);
			mcGameStage.addChild(txtB);

			// Play Game Button
			mcGameStage.addChild(plyBTN);
			plyBTN.x = (mcGameStage.width/2) - plyBTN.width/2;
			plyBTN.y = bgBox.y + bgBox.height+25;
			plyBTN.addEventListener(MouseEvent.CLICK, begin);
			
			function begin(event:MouseEvent):void {
				stage.removeChild(mcGameStage);
				gotoAndStop('gamePlay');
			}
			
		}
		
		private function simulatedScale() {
			//Simulated scale to get the correct height for the textBox
			safeMan['txt'].scaleX = 6;
			safeMan['txt'].scaleY = 6;
			safeMan['textBox'].scaleX = 6;
			safeMan['textBox'].scaleY = 6;
				
			safeMan['txt'].height = (safeMan['txt'].height-((5-safeMan['txt'].numLines)*((safeMan['textBox'].height/5)/2)))*0.2;
					
			safeMan['txt'].scaleX = 1;
			safeMan['txt'].scaleY = 1;
			safeMan['textBox'].scaleX = 1;
			safeMan['textBox'].scaleY = 1;
		}
		
		private function winScreen() {
			//Win screen
			//Place a green drop shadow on all correct safety men
			for (var i=0;i<safeManArray.length;i++) {
				safeManArray[i][0].filters = [greenShadow];
				safeManArray[i][0]['correct'] = true;
			}
			
			//Deletes extra movable safety men
			for (var k=0;k<manArray.length;k++) {
				if (manArray[k].parent == mcGameStage) mcGameStage.removeChild(manArray[k]);
			}
			
			extraNum = 0;
			safetyNum = 0;
			redXArray = new Array();
		}
		
		private function endGame() {
			//End screen if the done button has been pressed
			//Place a green drop shadow on all correct safety men
			for (var i=0;i<safeManArray.length;i++) {
				safeManArray[i][0].filters = [greenShadow];
				safeManArray[i][0]['correct'] = true;
			}
			
			//Initalizes the leftover safe men that have not been found
			for (var j=0;j<safetyMsg.length;j++) {
				if (safetyBoxes[j] != null) {
					safeMan = new man()
					mcGameStage.addChild(safeMan);
					safeMan.x = safetyLocations[j][0]+safeMan.width/4;
					safeMan.y = safetyLocations[j][1]-safetyMan.height/4;
					
					txtBox = new textBox();
					txtBox.x = 17.5;
					txtBox.y = 11.65;
					txtBox.buttonMode = true;
					safeMan.addChild(txtBox);
							
					safeMan['Msg'] = safetyMsg[j];
					safeMan['typed'] = true;
					safeMan['textBox'] = txtBox;
					safeMan['correct'] = false;
					initializeMsg(safeMan);
					
					safeMan.addChildAt(safeMan['txtMask'],safeMan.getChildIndex(safeMan['textBox'])+1);
					safeMan.addChildAt(safeMan['txt'],safeMan.getChildIndex(safeMan['txtMask']));
					zoomInEnable(safeMan);
					
					simulatedScale();
					safeMan.filters = [redShadow];
					
					safeManArray.push(new Array(safeMan,safeMan['Msg']));
				}
			}
			
			//Deletes extra movable safety men
			for (var k=0;k<manArray.length;k++) {
				if (manArray[k].parent == mcGameStage) mcGameStage.removeChild(manArray[k]);
			}
			
			extraNum = 0;
			safetyNum = 0;
			redXArray = new Array();
		}
		
	}
}