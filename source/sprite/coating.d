//          Copyright Mac Liu 2021. 
// Distributed under the Boost Software License, Version 1.0. 
//    (See accompanying file LICENSE_1_0.txt or copy at 
//          http://www.boost.org/LICENSE_1_0.txt)} 

module sprite.coating;

import sprite.member;
import sprite.reflectable;
import std.stdio;
import std.traits : BaseTypeTuple, BaseClassesTuple, FieldNameTuple, isDynamicArray;

abstract class Coating : BaseReflectable {
    public static Coating build(T)(T object) {
        return new CoatingImpl!T(object);
    }
}

class CoatingImpl(T) : Coating {
    private T object;
    private TypeInfo type;
    private MemberVariable[string] members;

    this(T object) {
        this.object = object;

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
    }

    public TypeInfo getType() {
        return this.type;
    }

    public MemberVariable[string] getMembers() {
        return this.members;
    }
}
 
 
 
