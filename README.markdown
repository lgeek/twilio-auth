Use case
--------

I normally only use public key-based SSH authentication, but sometimes I need to login from a machine which I don't control and without having my private key. My solution is to add a user which is allowed password authentication and to use sshd's ForceCommand to add a second layer of authentication for this user. After a normal SSH login with the user's password, this script sends a SMS containing a randomly generated one time password using Twilio. This OTP then needs to be entered at the second password prompt. Proof of having the phone acts as a second factor of authentication.

Install
-------

Note: you can install twilio-auth in another directory, just use the correct path in sshd_config.

    gem install twilio-ruby
    cd ~
    git clone git://github.com/lgeek/twilio-auth.git
    mkdir ~/.twilio-auth
    cp ./twilio-auth/config.json ~/.twilio-auth
    
Now enter your Twilio settings and phone number in ~/.twilio-auth/config.json.

Now test that twilio-auth is working correctly:

    SSH_CLIENT='0' ~/twilio-auth/twilio-auth.rb

If all went well, you should have received a text containing an OTP. After entering the correct OTP, a new shell should have started.

Finally enable twilio-auth for ssh logins. Here's what I've added in my sshd_config:

    Match User cosmin
	    ForceCommand /home/cosmin/twilio-auth/twilio-auth.rb
	    PasswordAuthentication yes

WARNING: By default twilio-auth permanently blocks the client's IP after entering the wrong OTP three times in a row. This can lock you out of your system. See the source code for how to change this into a temporary ban.

Logging in with twilio-auth
---------------------------

    ssh login@machine
    login@machine's password: 
    Enter the OTP: 6yqdibt
    Wrong OTP.
    Enter the OTP: 6yqdibto
    login@machine:~$ 

