// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

@include "github:electricimp/MessageManager/MessageManager.lib.nut"
//@include __PATH__+"/../MessageManager.lib.nut"
@include __PATH__+"/../ConnectionManager.nut"
@include __PATH__+"/../Constants.nut"

// LocalCallbacksTestCase
// Tests for MessageManager.DataMessage.onFail MessageManager.DataMessage.onTimeout, MessageManager.DataMessage.onAck, MessageManager.DataMessage.onReply
class LocalCallbacksTestCase extends ImpTestCase {

    function testOnFail() {
        return Promise(function(resolve, reject) {

            local counter = 0;
            local cm = getConnectionManager();
            local mm = MessageManager({
                "connectionManager": cm
            });

            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called");
            }.bindenv(this));

            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));

            local dataMessage = mm.send(MESSAGE_NAME, BASIC_MESSAGE);

            dataMessage.onFail(function(msg, reason, retry) {
                try {
                    counter++;
                    assertEqual(MESSAGE_NAME, msg.payload.name, "Wrong msg.payload.name: " + msg.payload.name);
                    assertEqual(BASIC_MESSAGE, msg.payload.data, "Wrong msg.payload.data: " + msg.payload.data);
                    assertEqual(MM_ERR_NO_CONNECTION, reason, "Wrong reason: " + reason);
                    if (counter == 1) {
                        cm.connect();
                        retry();
                        cm.disconnect();
                    } else {
                        resolve();
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));

            dataMessage.onReply(function(msg, response) {
                reject("DataMessage.onReply handler called");
            }.bindenv(this));

            cm.disconnect();

        }.bindenv(this));
    }

    function testOnTimeout() {
        return Promise(function(resolve, reject) {

            local counter = 0;
            local ts = 0;
            local messageTimeout = 2;
            local messageTimeoutInc = 0;
            local mm = MessageManager({
                "messageTimeout": messageTimeout
            });
            local results = {
                "onAck": false,
                "onTimeout": false,
                "onFail": false,
                "onReply": false
            };

            mm.beforeSend(function(msg, enqueue, drop) {
                enqueue();
            }.bindenv(this));

            mm.onTimeout(function(msg, wait, fail) {
                if (!results["onTimeout"]) reject("global onTimeout handler called before handlers.onTimeout");
            }.bindenv(this));

            mm.onFail(function(msg, reason, retry) {
                if (!results["onFail"]) reject("global onFail handler called before handlers.onFail");
            }.bindenv(this));

            mm.onReply(function(msg, response) {
                if (!results["onReply"]) reject("global onReply handler called before handlers.onReply");
            }.bindenv(this));

            local dataMessage = mm.send(MESSAGE_WITH_HUGE_DELAY, BASIC_MESSAGE);

            dataMessage.onTimeout(function(msg, wait, fail) {
                if (!results["onTimeout"]) results["onTimeout"] = true;
                try {
                    counter++;
                    assertEqual(MESSAGE_WITH_HUGE_DELAY, msg.payload.name, "Wrong msg.payload.name: " + msg.payload.name);
                    assertEqual(BASIC_MESSAGE, msg.payload.data, "Wrong msg.payload.data: " + msg.payload.data);
                    if (ts == 0) {
                        ts = time();
                    }
                    local shift = time() - ts;
                    switch (counter) {
                        case 1:
                            assertEqual(messageTimeoutInc, shift, "Wrong message timeout(1): " + shift + ", should be " + messageTimeoutInc);
                            messageTimeoutInc += messageTimeout;
                            wait();
                            break;
                        case 2:
                            assertEqual(messageTimeoutInc, shift, "Wrong message timeout(2): " + shift + ", should be " + messageTimeoutInc);
                            local w8 = 5;
                            messageTimeoutInc += w8;
                            wait(w8);
                            break;
                        case 3:
                            assertEqual(messageTimeoutInc, shift, "Wrong message timeout(3): " + shift + ", should be " + messageTimeoutInc);
                            fail();
                            break;
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));

            dataMessage.onFail(function(msg, reason, retry) {
                if (!results["onFail"]) results["onFail"] = true;
                if (counter == 3) {
                    resolve();
                } else {
                    reject("DataMessage.onFail handler called. Reason: " + reason);
                }
            }.bindenv(this));

            dataMessage.onReply(function(msg, response) {
                if (!results["onFail"]) results["onFail"] = true;
                reject("DataMessage.onReply handler called");
            }.bindenv(this));

        }.bindenv(this));
    }

    function testOnAck() {
        return Promise(function(resolve, reject) {

            local mm = MessageManager();

            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called");
            }.bindenv(this));

            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));

            mm.onAck(function(msg) {
                reject("onAck handler called");
            }.bindenv(this));

            local dataMessage = mm.send(MESSAGE_WITHOUT_RESPONSE, BASIC_MESSAGE);

            dataMessage.onFail(function(msg, reason, retry) {
                reject("DataMessage.onFail handler called. Reason: " + reason);
            }.bindenv(this));

            dataMessage.onReply(function(msg, response) {
                reject("DataMessage.onReply handler called");
            }.bindenv(this));

            dataMessage.onAck(function(msg) {
                try {
                    assertEqual(BASIC_MESSAGE, msg.payload.data, ERR_REQ_RES_NOT_IDENTICAL);
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));

        }.bindenv(this));
    }

    function testOnReply() {
        return Promise(function(resolve, reject) {

            local mm = MessageManager();

            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));

            local dataMessage = mm.send(MESSAGE_NAME, BASIC_MESSAGE);

            dataMessage.onReply(function(msg, response) {
                try {
                    assertEqual(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    assertEqual(BASIC_MESSAGE, msg.payload.data, ERR_REQ_RES_NOT_IDENTICAL);
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));

        }.bindenv(this));
    }
}