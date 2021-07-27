//          Copyright Mac Liu 2021. 
// Distributed under the Boost Software License, Version 1.0. 
//    (See accompanying file LICENSE_1_0.txt or copy at 
//          http://www.boost.org/LICENSE_1_0.txt)} 

module sprite.instance;

import sprite.distiller;

class InstanceStore {
    protected shared(Distiller) distiller;

    abstract TypeInfo getRegisteredType();
    abstract InstanceStore linkTo(InstanceStore anotherSotre);
    abstract Object getInstance();
}

class InstanceStoreImpl(InstanceType) : InstanceStore {
    private TypeInfo registeredType;
    private InstanceType instance;
    private InstanceStore anotherStore;
    private bool autowired;

    this(TypeInfo registeredType, InstanceType instance, shared(Distiller) distiller) {
        this.registeredType = registeredType;
        this.instance = instance;
        this.autowired = false;
        this.distiller = distiller;
    }

    override TypeInfo getRegisteredType() {
        return this.registeredType;
    }

    override InstanceStore linkTo(InstanceStore anotherSotre) {
        this.anotherStore = anotherStore;
        return this;
    }

    override Object getInstance() {
        if (!this.autowired) {
            this.distiller.autowiring( this.instance);
            this.autowired = true;
        }
        return this.instance;
    }
}
