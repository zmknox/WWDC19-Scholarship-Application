# Tell us about the features and technologies that you used in your Swift playground, in 500 words or less.

I designed this playground to give users a way to experience the various symptoms of a vision based disabilities or eye diseases, and the effects they have on vision. I did this by simulating them: applying different filters to the live camera of the device. People are constantly using image filters when taking photos for Instagram or Snapchat, and I wanted to play off that to give a fun and familiar interface that shows these various symptoms. I myself have a major visual impairment called Achromatopsia, and wanted something I could use to easily show others an example so they can gain a better understanding of what my vision is like. Words can only go so far, but a simulation can really help put these effects into perspective.

My initial goal was to provide the three filters which affected myself, near-sightedness, very light sensitive, and fully colorblind. Being able to combine these makes it possible to give a fully sighted user an idea of what it can be like to see through my eyes. In developing this playground, however, I thought it would be far more interesting if I added even more filters for other eye disease symptoms as well. With some research, I was able to find many more symptoms that I was able to simulate. Some of these affect field of view, like having no central or no peripheral vision, which others have more drastic effects, like having a cataract or severe glaucoma. I was happily surprised by how much I was able to learn about the world of vision related disabilities and diseases by implementing simulations in this playground.

This playground required I use image based APIs—specifically AVFoundation and Core Image—to obtain and manipulate the camera view, in addition to the more standard UIKit controls. I had never delved into using the camera or any significant image manipulation, so this provided me with a good challenge, and now a more broad knowledge of how to use the available APIs. I was most challenged by live updating a view with Core Image filters, such as for the Colorblind and Cataract filters, to display while you were actively moving the camera. I think it’s really cool to be able to manipulate your vision through a camera though this pseudo-AR experience, and I’m excited to use it more in the future. As far as image resources used in the UI, I created all the icons, overlays, and buttons using both Affinity Designer and Pixelmator Pro.

My vision is an important aspect of my life, and I’m always looking for ways to help others better understand what it’s like. I hope this playground will help others with the same desire to explain their vision disabilities as well, helping the world better understand what they see.