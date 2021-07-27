//          Copyright Mac Liu 2021. 
// Distributed under the Boost Software License, Version 1.0. 
//    (See accompanying file LICENSE_1_0.txt or copy at 
//          http://www.boost.org/LICENSE_1_0.txt)} 

module sprite.reflectable;

import sprite.member;
import std.stdio;
import std.traits : BaseTypeTuple, BaseClassesTuple, FieldNameTuple, isDynamicArray;


interface BaseReflectable {
    public TypeInfo getType();
    public MemberVariable[string] getMembers();
}

class Reflectable(T) : BaseReflectable {
    private TypeInfo type;
    private MemberVariable[string] members;

    this(T)(T o){
        this.type = typeid(T);

        foreach (memberIndex, name; FieldNameTuple!T) {
            alias MemberType = typeof(T.tupleof[memberIndex]);

            MemberVariable member = {
                type: typeid(MemberType),
                name: name,
                attributes: [],
                memberIndex: memberIndex,
            };

            foreach (attribute; __traits(getAttributes, T.tupleof[memberIndex])) {
                member.attributes ~= typeid(attribute);
            }

            members[member.name] = member;

        }
        writeln( this.type.toString());
        writeln( this.members);
    }

    public TypeInfo getType() {
        return this.type;
    }

    public MemberVariable[string] getMembers() {
        return this.members;
    }
}
 
 
 
