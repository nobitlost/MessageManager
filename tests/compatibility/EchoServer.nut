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

// EchoServer
// This file should be included into agent or device code file, depending on witch one will be echo server (will respond with received message)

local cm = getConnectionManager();
local onPartnerConnected = function(reply) {
    cm.connect();
    reply(REPLY_NO_MESSAGES);
};
local config = {
    "onPartnerConnected": onPartnerConnected.bindenv(this),
    "connectionManager" : cm
};

local mm = MessageManager(config);

mm.on(MESSAGE_NAME, function(message, reply) {
    reply(message);
}.bindenv(this));

mm.on(MESSAGE_WITHOUT_RESPONSE, function(message, reply) {
    // do nothing
}.bindenv(this));

mm.on(MESSAGE_WITH_DELAY, function(message, reply) {
    imp.sleep(MESSAGE_WITH_DELAY_SLEEP);
    reply(message);
}.bindenv(this));

mm.on(MESSAGE_WITH_HUGE_DELAY, function(message, reply) {
    imp.sleep(MESSAGE_WITH_DELAY_DEEP_SLEEP);
    reply(message);
}.bindenv(this));
