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
@include __PATH__+"/../Base.nut"

// ConnectionRealTestCase
// Tests for MessageManager constructor options (onPartnerConnected, onConnectedReply, connectionManager)
// Test connection with real ConnectionManager
class ConnectionRealTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }
    
    function testConnection() {
        if (isAgentSide()) {
            info("ConnectionManager is a device-side only library, so we skip this test that running on the agent");
            return Promise(function(resolve, reject) {
                resolve();
            });
        }
        return Promise(function(resolve, reject) {
            local partnerConnected = false;
            local connectedReply = null;
            local cm = getConnectionManager(false);
            local onPartnerConnected = function(reply) {
                isAgentSide() && cm.connect();
                reply(REPLY_NO_MESSAGES);
                partnerConnected = true;
            }.bindenv(this);
            local onConnectedReply = function(data) {
                connectedReply = data;
            }.bindenv(this);
            local mm = MessageManager({
                "firstMessageId":     msgId,
                "nextIdGenerator":    msgIdGenerator,
                "connectionManager":  cm,
                "onPartnerConnected": onPartnerConnected.bindenv(this),
                "onConnectedReply":   onConnectedReply.bindenv(this)
            });
            imp.wakeup(2, function() {
                try {
                    assertTrue(partnerConnected, "Partner is not connected");
                    assertDeepEqualWrap(REPLY_NO_MESSAGES, connectedReply, "Wrong connected reply");
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
        }.bindenv(this));
    }
}
