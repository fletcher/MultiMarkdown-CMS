// Copyright (C) 2010  Fletcher T. Penney <fletcher@fletcherpenney.net>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the
//    Free Software Foundation, Inc.
//    59 Temple Place, Suite 330
//    Boston, MA 02111-1307 USA

function writeCommenterGreeting(){
	container = document.getElementById("commenter-greeting");
	var content;
	var openId;
	openId = getCookie('OpenID');
	user = getCookie('User');
    
	if (openId != '') {
		content = '<p>You are signed in as <a href="' + openId + '">' + openId + '</a>.  You may <a href="javascript:forgetMe()">sign out</a>.</p><form action="/cgi/submit_comment.cgi" method="PUT"><label>Name</label><input type="text" name="user" side="25" value="' + user + '"/><label>Comments (may contain MultiMarkdown syntax, but not HTML)</label><textarea name="text" rows="15" columns="40"></textarea><input type="submit" accesskey="s" name="post" value="Submit" /></form>';
	} else {
	content = '<p>Please sign in using your <a href="http://en.wikipedia.org/wiki/Openid">OpenID</a>. If you don\'t have an OpenID, you may also email me.</p> <form action="/cgi/openid_send.cgi" method="PUT" > <img src="/images/openid.png" style="border:0px;	background-color:transparent;margin:0px;padding:0px;"/><label for="openid-field">OpenID URL</label><input id="openid-field" type="text" name="openid" size="25"/><input type="submit" value="Login"/></form> '; 
		}
	
	container.innerHTML = content;
}


// Remainder of this document is Copyright (c) 1996-1997 Athenia Associates.
// http://www.webreference.com/js/
// License is granted if and only if this entire
// copyright notice is included. By Tomer Shiran.

    function setCookie (name, value, expires, path, domain, secure) {
        var curCookie = name + "=" + escape(value) + (expires ? "; expires=" + expires.toGMTString() : "") +
            (path ? "; path=" + path : "") + (domain ? "; domain=" + domain : "") + (secure ? "secure" : "");
        document.cookie = curCookie;
    }

    function getCookie (name) {
        var prefix = name + '=';
        var c = document.cookie;
        var nullstring = '';
        var cookieStartIndex = c.indexOf(prefix);
        if (cookieStartIndex == -1)
            return nullstring;
        var cookieEndIndex = c.indexOf(";", cookieStartIndex + prefix.length);
        if (cookieEndIndex == -1)
            cookieEndIndex = c.length;
        return unescape(c.substring(cookieStartIndex + prefix.length, cookieEndIndex));
    }

    function deleteCookie (name, path, domain) {
        if (getCookie(name))
            document.cookie = name + "=" + ((path) ? "; path=" + path : "") +
                ((domain) ? "; domain=" + domain : "") + "; expires=Thu, 01-Jan-70 00:00:01 GMT";
    }

    function fixDate (date) {
        var base = new Date(0);
        var skew = base.getTime();
        if (skew > 0)
            date.setTime(date.getTime() - skew);
    }

    function rememberMe (f) {
        var now = new Date();
        fixDate(now);
        now.setTime(now.getTime() + 365 * 24 * 60 * 60 * 1000);
        now = now.toGMTString();
        if (f.author != undefined)
           setCookie('mtcmtauth', f.author.value, now, '/', '', '');
        if (f.email != undefined)
           setCookie('mtcmtmail', f.email.value, now, '/', '', '');
        if (f.url != undefined)
           setCookie('mtcmthome', f.url.value, now, '/', '', '');
    }

    function forgetMe (f) {
		deleteCookie('OpenID', '/', '');
		deleteCookie('Comment', '/', '');
		deleteCookie('User', '/', '');
		writeCommenterGreeting();
    }


