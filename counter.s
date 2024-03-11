.define LED_ADDRESS 0x1000
.define SW_ADDRESS 0x3000

		mv		r5, #0
		mvt		r6, #LED_ADDRESS
COUNT:	st		r5, [r6]
		add		r5, #1


				//delay

				// Delay loop for controlling speed of scrolling
          mv     r3, #DELAY
          ld     r3, [r3]              // delay counter 
OUTER:    mvt    r0, #SW_ADDRESS       // point to SW port 
          ld     r4, [r0]              // load inner loop delay from SW 
          add    r4, #1                // in case 0 was read
INNER:    sub    r4, #1                // decrement inner loop counter 
          bne    INNER                 // continue inner loop 
          sub    r3, #1                // decrement outer loop counter 
          bne    OUTER                 // continue outer loop 

          b     COUNT



DELAY:    .word  250
