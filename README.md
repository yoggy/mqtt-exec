mqtt-exec.rb
====

a simple process server using MQTT.

    $ mkdir ~/work/
    $ cd work
    $ git clone https://github.com/yoggy/mqtt-exec.git
    $ cd mqtt-exec
    
    $ cp config.yaml.sample config.yaml
    $ vi config.yaml
      ※  edit host, port, username, ..., etc
    
    $ cp topic2cmd.csv.sample topic2cmd.csv
    $ vi topic2cmd.csv
      ※ edit subscribe_topic, command, stdout_topic

    $ sudo gem install mqtt
    $ ./mqtt-exec.rb

Copyright and license
----
Copyright (c) 2017 yoggy

Released under the [MIT license](LICENSE.txt)
