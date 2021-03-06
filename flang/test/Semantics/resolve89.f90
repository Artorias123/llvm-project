! RUN: %B/test/Semantics/test_errors.sh %s %flang %t
! C750 Each bound in the explicit-shape-spec shall be a specification
! expression in which there are no references to specification functions or
! the intrinsic functions ALLOCATED, ASSOCIATED, EXTENDS_- TYPE_OF, PRESENT,
! or SAME_TYPE_AS, every specification inquiry reference is a constant
! expression, and the value does not depend on the value of a variable.
impure function impureFunc()
  integer :: impureFunc

  impureFunc = 3
end function impureFunc

pure function pureFunc()
  integer :: pureFunc

  pureFunc = 3
end function pureFunc

module m
  real, allocatable :: mVar
end module m

subroutine s(iArg, allocArg, pointerArg, arrayArg, ioArg, optionalArg)
  use m
  implicit logical(l)
  integer, intent(in) :: iArg
  real, allocatable, intent(in) :: allocArg
  real, pointer, intent(in) :: pointerArg
  integer, dimension(:), intent(in) :: arrayArg
  integer, intent(inout) :: ioArg
  real, optional, intent(in) :: optionalArg

  ! These declarations are OK since they're not in a derived type
  real :: realVar
  real, volatile :: volatileVar
  real, dimension(merge(1, 2, allocated(allocArg))) :: realVar1
  real, dimension(merge(1, 2, associated(pointerArg))) :: realVar2
  real, dimension(merge(1, 2, is_contiguous(arrayArg))) :: realVar3
  real, dimension(ioArg) :: realVar4
  real, dimension(merge(1, 2, present(optionalArg))) :: realVar5

  ! statement functions referenced below
  iVolatileStmtFunc() = 3 * volatileVar
  iImpureStmtFunc() = 3 * impureFunc()
  iPureStmtFunc() = 3 * pureFunc()

  ! This is OK
  real, dimension(merge(1, 2, allocated(mVar))) :: rVar


  integer :: var = 3
    !ERROR: Invalid specification expression: reference to impure function 'ivolatilestmtfunc'
  real, dimension(iVolatileStmtFunc()) :: arrayVarWithVolatile
    !ERROR: Invalid specification expression: reference to impure function 'iimpurestmtfunc'
  real, dimension(iImpureStmtFunc()) :: arrayVarWithImpureFunction
    !ERROR: Invalid specification expression: reference to statement function 'ipurestmtfunc'
  real, dimension(iPureStmtFunc()) :: arrayVarWithPureFunction
  real, dimension(iabs(iArg)) :: arrayVarWithIntrinsic

  type arrayType
    !ERROR: Invalid specification expression: derived type component not allowed to reference variable 'var'
    real, dimension(var) :: varField
    !ERROR: Invalid specification expression: reference to impure function 'ivolatilestmtfunc'
    real, dimension(iVolatileStmtFunc()) :: arrayFieldWithVolatile
    !ERROR: Invalid specification expression: reference to impure function 'iimpurestmtfunc'
    real, dimension(iImpureStmtFunc()) :: arrayFieldWithImpureFunction
    !ERROR: Invalid specification expression: reference to statement function 'ipurestmtfunc'
    real, dimension(iPureStmtFunc()) :: arrayFieldWithPureFunction
    !ERROR: Invalid specification expression: derived type component not allowed to reference variable 'iarg'
    real, dimension(iabs(iArg)) :: arrayFieldWithIntrinsic
    !ERROR: Invalid specification expression: reference to intrinsic 'allocated' not allowed for derived type components
    real, dimension(merge(1, 2, allocated(allocArg))) :: realField1
    !ERROR: Invalid specification expression: reference to intrinsic 'associated' not allowed for derived type components
    real, dimension(merge(1, 2, associated(pointerArg))) :: realField2
    !ERROR: Invalid specification expression: non-constant reference to inquiry intrinsic 'is_contiguous' not allowed for derived type components
    real, dimension(merge(1, 2, is_contiguous(arrayArg))) :: realField3
    !ERROR: Invalid specification expression: derived type component not allowed to reference variable 'ioarg'
    real, dimension(ioArg) :: realField4
    !ERROR: Invalid specification expression: reference to intrinsic 'present' not allowed for derived type components
    real, dimension(merge(1, 2, present(optionalArg))) :: realField5
  end type arrayType

end subroutine s

subroutine s1()
  ! C750, check for a constant specification inquiry that's a type parameter
  ! inquiry which are defined in 9.4.5
  type derived(kindParam, lenParam)
    integer, kind :: kindParam = 3
    integer, len :: lenParam = 3
  end type

  contains
    subroutine inner (derivedArg)
      type(derived), intent(in), dimension(3) :: derivedArg
      integer :: localInt

      type(derived), parameter :: localderived = derived()

      type localDerivedType
        ! OK because the specification inquiry is a constant
        integer, dimension(localDerived%kindParam) :: goodField
        !ERROR: Invalid specification expression: non-constant reference to a type parameter inquiry not allowed for derived type components
        integer, dimension(derivedArg%lenParam) :: badField
      end type localDerivedType

      ! OK because we're not defining a component
      integer, dimension(derivedArg%kindParam) :: localVar
    end subroutine inner
end subroutine s1
