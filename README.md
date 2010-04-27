Snifter
================

This project is to help me reverse engineer certain HTTP based protocols who could not
be bothered to document what the hell is going on (*COUGHSVN*).  

It has a proxymachine instance that you can filter all HTTP traffic through that will
log all the traffic to a redis instance and then you can use the included sinatra 
server to browse that data.

It currently assumes all the data will be XML based and will simplify the XML data 
for simpler comparison, but you can also click on 'details' to see the full, syntax
highlighted XML.

![screenshot](http://img.skitch.com/20100427-j724ebpkt73ere62pb4usayi43.jpg)

ToDo
================

* To be more generally useful, it might be nice to only do the XML magic if the body
  has an xml header as the first line or something.

* Also want to do side by side views of sessions, possibly even highlighting the 
  major differences between two sessions.

* Make the port assignments for the PM specified on the command line when you launch it.


License
================

MIT.

