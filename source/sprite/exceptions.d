//          Copyright Mac Liu 2021. 
// Distributed under the Boost Software License, Version 1.0. 
//    (See accompanying file LICENSE_1_0.txt or copy at 
//          http://www.boost.org/LICENSE_1_0.txt)} 
 
module sprite.exceptions;

import std.format;
import std.exception;

class ResolveException : Exception {
    this(string message, TypeInfo resolveType) {
        super( format( "Exception while resolving type %s: %s", resolveType.toString(), message));
    }

    this(Throwable cause, TypeInfo resolveType){
        super( format( "Exception while resolving type %s", resolveType.toString()), cause);
    }
}
