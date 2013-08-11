EZID API
========

[![Build Status](https://secure.travis-ci.org/no-reply/Ruby-EZID.png)](http://travis-ci.org/no-reply/bagit)

https://rubygems.org/gems/ezid

This API is part of work to integrate EZID into the OregonDigital Hydra DAMS system in development. It is currently in use for development on that system; we don't recommend it for production use at this time.


    session = Ezid::ApiSession.new
    # mint an id with the test account
    i = session.mint()
    i.identifier # =>  "ark:/99999/fk4058n1x"

    # or specify your own id
    i = session.create('monkey')
    i.identifier # =>  "ark:/99999/fk4monkey"

The ApiSession object will also accept a username, password, identifer scheme and naa like this: Ezid::ApiSession.new('username', 'password', :doi, '12345')


License
-------

[![cc0](http://i.creativecommons.org/p/zero/1.0/88x31.png)](http://creativecommons.org/publicdomain/zero/1.0/)
