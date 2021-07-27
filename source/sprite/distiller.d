//          Copyright Mac Liu 2021. 
// Distributed under the Boost Software License, Version 1.0. 
//    (See accompanying file LICENSE_1_0.txt or copy at 
//          http://www.boost.org/LICENSE_1_0.txt)} 

module sprite.distiller;

import sprite.instance : InstanceStore, InstanceStoreImpl;
import sprite.inject : Inject;
import sprite.postconstruct : HavePostConstruct;
import sprite.exceptions;
import sprite.reflectable : BaseReflectable;
import std.algorithm : canFind;
import std.traits : BaseTypeTuple, BaseClassesTuple, FieldNameTuple, isDynamicArray;
import std.stdio;

private struct UseMemberType {
}

synchronized class Distiller {
    private InstanceStore[][TypeInfo] registeredInstances;
    private InstanceStore[] injectionStack;

    public InstanceStore push(InstanceType)(InstanceType instance) {
        return push!(InstanceType, InstanceType)( instance);
    }

    public InstanceStore push(SuperType, InstanceType: SuperType)(InstanceType instance) if (! is(InstanceType == struct)) {
        TypeInfo registeredType = typeid(SuperType);
        //TypeInfo_Class instanceType = typeid(InstanceType);

        auto instanceStore = new InstanceStoreImpl!InstanceType( registeredType, instance, this);

        static if (! is (SuperType == InstanceType)) {
            push!(InstanceType,InstanceType)( instance).linkTo( instanceStore);
        }

        registeredInstances[registeredType] ~= cast(shared(InstanceStore)) instanceStore;
        return instanceStore;
    }

    public InstanceType pull(InstanceType)() if (!is(InstanceType == struct)) {
        return pull!(InstanceType, InstanceType);
    }

    public InstanceType pull(InstanceType, QualifiedType: InstanceType)() {
        TypeInfo instanceType = typeid(InstanceType);
        TypeInfo qualifiedType = typeid(QualifiedType);

        auto candidates = instanceType in this.registeredInstances;

        if (!candidates) {
            throw new ResolveException( "Type not registered.", instanceType);
        }

        auto instanceStore = findQualifiedInstance( instanceType, qualifiedType, cast(InstanceStore[]) *candidates);

        if (instanceStore is null) {
            throw new ResolveException( "Type not find.", instanceType);
        }

        auto newInstance = dependenceInjection!QualifiedType( instanceStore);

        if (auto postConstructable = cast(HavePostConstruct) newInstance) {
            postConstructable.postConstruct();
        }

        return newInstance;
    }

    private QualifiedType dependenceInjection(QualifiedType)(InstanceStore instanceStore) {
        QualifiedType instance;

        if (!(cast(InstanceStore[]) this.injectionStack).canFind( instanceStore)) {
            this.injectionStack ~= cast(shared(InstanceStore)) instanceStore;
            instance = cast(QualifiedType) instanceStore.getInstance();
            this.injectionStack = this.injectionStack[0 .. $ - 1];
        }
        return instance;
    }

    private InstanceStore findQualifiedInstance(TypeInfo resolveType, TypeInfo qualifierType, InstanceStore[] candidates) {
        if (resolveType == qualifierType) {
            if (candidates.length > 1) {
                throw new ResolveException( "Multiple qualified candidates available: Please use a qualifier.", resolveType);
            }

            return candidates[0];
        }

        return findInstance( candidates, qualifierType);
    }

    private InstanceStore findInstance(InstanceStore[] candidates, TypeInfo instanceType) {
        foreach (entry; candidates) {
            if (entry.getRegisteredType() == instanceType) {
                return entry;
            }
        }

        return null;
    }

    shared(Distiller) opBinary(string op, ObjectType)(ObjectType rhs) if (op == "<<" && !is(ObjectType == struct)) {
        static if (isDynamicArray!ObjectType) {
            foreach (entry; cast(Object[]) rhs) {
                alias EntryType = typeof(entry);

                if (auto reflectable = cast(BaseReflectable) entry) {
                    writeln( reflectable.getType());
                    //writeln( reflectable.getMembers());


                    //reflectable.registration(this);
                    //this.push!(ReflectableType, ReflectableType)( reflectable);
                }
                this.push!(EntryType, EntryType)( entry);
            }
        } else {
            this.push!(ObjectType, ObjectType)( rhs);
        }
        return this;
    }

    T opCast(T)() {
        return pull!(T, T);
    }

    void autowiring(Type)(Type instance) {
        // Recurse into base class if there are more between Type and Object in the hierarchy
        static if (BaseClassesTuple!Type.length > 1) {
            autowiring!(BaseClassesTuple!Type[0])( instance);
        }

        foreach (index, name; FieldNameTuple!Type) {
            autowiringMember!(name, index, Type)( instance);
        }
    }

    private void autowiringMember(string member, size_t memberIndex, Type)(Type instance) {
        foreach (attribute; __traits(getAttributes, Type.tupleof[memberIndex])) {
            static if (is(attribute == Inject!T, T)) {
                injectInstance!(member, memberIndex, typeof(attribute.qualifier))( instance);
            } else static if (__traits(isSame, attribute, Inject)) {
                injectInstance!(member, memberIndex, UseMemberType)( instance);
            }
        }
    }

    private void injectInstance(string member, size_t memberIndex, QualifierType, Type)(Type instance) {

        if (instance.tupleof[memberIndex] is null) {
            alias MemberType = typeof(Type.tupleof[memberIndex]);

            injectInstance!(member, memberIndex, false, MemberType, QualifierType)( instance);
        }
    }

    private void injectInstance(string member, size_t memberIndex,bool isOptional, MemberType, QualifierType, Type)(Type instance) {
        MemberType qualifiedInstance;

        static if (!is(QualifierType == UseMemberType)) {
            qualifiedInstance = this.pull!(MemberType, QualifierType);
        } else {
            qualifiedInstance = this.pull!(MemberType, MemberType);
        }

        instance.tupleof[memberIndex] = qualifiedInstance;
    }
}
