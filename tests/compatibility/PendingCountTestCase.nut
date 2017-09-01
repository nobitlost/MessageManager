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

@include __PATH__+"/../Base.nut"

// PendingCountTestCase
// Tests for MessageManager.getPendingCount()
class PendingCountTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }
    
    function testConsistently() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            local limit = 10;
            local index = 0;
            local next;
            next = function() {
                try {
                    if (++index >= limit) {
                        resolve();
                        return;
                    }
                    mm.onReply(function(msg, response) {
                        imp.wakeup(0.01, next.bindenv(this));
                    }.bindenv(this));
                    mm.send(MESSAGE_NAME, BASIC_MESSAGE);
                    local pendingCount = mm.getPendingCount();
                    assertDeepEqualWrap(1, pendingCount, "Wrong MessageManager.getPendingCount() value");
                } catch (ex) {
                    reject(ex);
                }
            };
            next();
        }.bindenv(this));
    }

    function testSimultaneously() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            local limit = 5;
            for (local i = 0; i < limit; i++) {
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }
            try {
                local pendingCount = mm.getPendingCount();
                assertDeepEqualWrap(limit, pendingCount, "Wrong MessageManager.getPendingCount() value");
                resolve();
            } catch (ex) {
                reject(ex);
            }
        }.bindenv(this))
    }
}
