// set and send initial state
isHacking <- 0;
agent.send("hacking", { state=isHacking, boot=true });

// configure LED
led <- hardware.pin9;
led.configure(DIGITAL_OUT)
led.write(isHacking);

// configure the button
button <- hardware.pin1;
button.configure(DIGITAL_IN_PULLUP, function() {    
    imp.sleep(0.05); // software debounce
    
    local state = button.read();
    // button down
    if (state == 1) {
        // invert the state
        isHacking = 1 - isHacking;
        // set LED, then send to agent
        led.write(isHacking);
        agent.send("hacking", {state=isHacking, boot=false });
    }
});

