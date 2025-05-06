void setup() {
  Serial.begin(9600);                
  pinMode(LED_BUILTIN, OUTPUT);    
}

void loop() {
  if (Serial.available()) {
    char command = Serial.read(); 

    Serial.println("Communication Successful"); 
      delay(100);

    if (command == 'A') {
      digitalWrite(LED_BUILTIN, HIGH);  
      Serial.println("LED is ON"); 
      delay(100);
    }else{
      digitalWrite(LED_BUILTIN, LOW);
      Serial.println("LED is OFF"); 
      delay(100);

    }

    Serial.println("Received:");
    delay(100);
    Serial.println(command);
    delay(100);


  }
}
