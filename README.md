# YJAOEZTOC
Simpler SAP / ABAP Migration / Transport of Copies utility.
This app makes working with TOC's and Transports less error prone.

It also makes it easier to build / merge task objects into TOC's

Change your Target System/Client and you're ready to go.

There are a lot of other Classes for the ALV / Generics but they
are all rolled into a single ABAP Source file so you can get going
quicker.

You may split it out into separate Includes/Objects as you see fit.

You will need to add your own screen 100.  See the Screen shot .png's.

I like to use the Two transaction approach to avoid the selection screen
on startup.  I shouldn't have had to do this but as ABAP reaches it's
sunset little things start breaking so I had to use the Two Transaction
approach because I couldn't find a way to make it do what I wanted.

There's nothing secret about how the transports are manipulated.  It's all done
via Function Modules.  You will see that in the opening comments.  It works
just as if you are running the transactions themselves, nothing secret or
direct table modifications.

If you can't figure out how the Application Side works, you probably shouldn't be
fooling around with transports.

The ALV side is something else altogether different.  I wrote that too so no
problems there.

It's actually the simplest ALV utility you will ever use.  Half a dozen lines of code
and you have an ALV report with excellent functionality.
