#! parrot
# Copyright (C) 2006-2007, Parrot Foundation.
# $Id$

=head1 NAME

t/pmc/namepspace.t - test NameSpace PMC

=head1 SYNOPSIS

    % prove t/pmc/namespace.t

=head1 DESCRIPTION

Tests the NameSpace PMC.

=cut

.sub main :main
    .include 'test_more.pir'
    plan(12)

    create_namespace_pmc()
    verify_namespace_type()
    get_global_opcode()
    get_sub_from_namespace_hash()
    get_namespace_from_sub()
.end

# L<PDD21/Namespace PMC API/=head4 Untyped Interface>
.sub 'create_namespace_pmc'
    push_eh eh1
    $P0 = new ['NameSpace']
    pop_eh
    ok(1, "Create new Namespace PMC")
    goto _end
  eh1:
    ok(0, "Could not create Namespace PMC")
  _end:
.end

.sub 'verify_namespace_type'
    $P0 = get_global "Foo"
    typeof $S0, $P0
    is($S0, "NameSpace", "A NameSpace is a NameSpace")
.end

# L<PDD21//>
.sub 'get_global_opcode'
    push_eh eh1
    $P0 = get_global "baz"
    $S0 = $P0()
    pop_eh
    is($S0, "", "Can get_global a .sub")
    goto test2
  eh1:
    ok(0, "Cannot get_global a .sub")

  test2:
    push_eh eh2
    $P0 = get_global ["Foo"], "baz"
    $S0 = $P0()
    pop_eh
    is($S0, "Foo", "Get Sub from NameSpace")
    goto test3
  eh2:
    ok(0, "Cannot get Sub from NameSpace Foo")

  test3:
    push_eh eh3
    $P0 = get_global ["Foo";"Bar"], "baz"
    $S0 = $P0()
    pop_eh
    is($S0, "Foo::Bar", "Get Sub from nested NameSpace")
    goto test4
  eh3:
    ok(0, "Cannot get Sub from NameSpace Foo::Bar")

  test4:
    push_eh eh4
    $P0 = get_global ["Foo"], "SUB_THAT_DOES_NOT_EXIST"
    $P0()
    ok(0, "Found and invoked a non-existant sub")
    goto test5
  eh4:
    # Should we check the exact error message here?
    ok(1, "Cannot invoke a Sub that doesn't exist")

  test5:
    # this used to behave differently from the previous case.
    push_eh eh5
    $P0 = get_global ["Foo";"Bar"], "SUB_THAT_DOES_NOT_EXIST"
    $P0()
    ok(0, "Found and invoked a non-existant sub")
    goto _end
  eh5:
    # Should we check the exact error message here?
    ok(1, "Cannot invoke a Sub that doesn't exist")
  _end:
.end

.sub 'get_sub_from_namespace_hash'
    $P0 = get_global "Foo"
    $I0 = does $P0, 'hash'
    ok($I0, "Namespace does hash")

    $P1 = $P0["baz"]
    $S0 = $P1()
    is($S0, "Foo", "Get the Sub from the NameSpace as a Hash")

    $P1 = $P0["Bar"]
    $P2 = $P1["baz"]
    $S0 = $P2()
    is($S0, "Foo::Bar", "Get the Sub from the nested NameSpace as a Hash")
.end

.sub 'get_namespace_from_sub'
    $P0 = get_global "baz"
    $P1 = $P0."get_namespace"()
    $S0 = $P1
    is($S0, "parrot", "Get the root namespace from a sub in the root namespace")

    $P0 = get_global ["Foo"], "baz"
    $P1 = $P0."get_namespace"()
    $S0 = $P1
    is($S0, "Foo", "Get the namespace from a Sub in the NameSpace")
.end


##### TEST NAMESPACES AND FUNCTIONS #####
# These functions and namespaces are used for the tests above

.namespace []

.sub 'baz'
    .return("")
.end

.namespace ["Foo"]
.sub 'baz'
    .return("Foo")
.end

.namespace ["Foo";"Bar"]
.sub 'baz'
    .return("Foo::Bar")
.end
