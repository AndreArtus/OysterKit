/*
Copyright (c) 2014, RED When Excited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


import Foundation


class Branch : TokenizationState {
    var transientTransitionState:Branch?
    
    override func stateClassName()->String {
        return "Branch"
    }
    
    
    init(){
       super.init()
    }
    
    init(states:Array<TokenizationState>){
        super.init()
        branches = states
    }


    override func couldEnterWithCharacter(character: UnicodeScalar, controller: TokenizationController) -> Bool {
        for branch in branches{
            if branch.couldEnterWithCharacter(character, controller: controller){
                return true
            }
        }
        return false
    }
    
    //You may wish to over-ride to set the context for improved error messages
    override func consume(character:UnicodeScalar, controller:TokenizationController) -> TokenizationStateChange{
        for branch in branches{
            if (branch.couldEnterWithCharacter(character, controller: controller)){
                return TokenizationStateChange.Transition(newState: branch, consumedCharacter:false)
            }
            
        }

        return TokenizationStateChange.Exit(consumedCharacter: false)
    }
    

    //
    // Serialization
    //
    func serializeStateArray(indentation:String, states:Array<TokenizationState>)->String{
        if states.count == 1 {
            return states[0].serialize(indentation)
        }
        var output = ""
        var first = true
        for state in states {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\n"
            output+=indentation+state.serialize(indentation)
        }
        
        return output
    }
    

    
    override func serialize(indentation:String)->String{
        var output = "{"+serializeStateArray(indentation+"\t",states: branches)+"}"
        
        if branches.count > 1 {
            output+="\n"
        }
        
        return output
    }
    
    func selfSatisfiedBranchOutOfStateTransition(consumedCharacter:Bool, controller:TokenizationController, withToken:Token?)->TokenizationStateChange{
        emitToken(controller, token: withToken)

        if branches.count == 0 {
            return TokenizationStateChange.Exit(consumedCharacter: consumedCharacter)
        } else {
            if !transientTransitionState{
                transientTransitionState = Branch()
            }
            
            transientTransitionState!.branches = self.branches
            
            //If we can either enter the transient state or we did consume the character
            if transientTransitionState!.couldEnterWithCharacter(controller.currentCharacter(),controller: controller) || consumedCharacter{
                return TokenizationStateChange.Transition(newState: transientTransitionState!, consumedCharacter: consumedCharacter)
            }

            return TokenizationStateChange.Exit(consumedCharacter: consumedCharacter)
        }
    }
    
    @final func isClosed(usingList:[TokenizationState])->Bool{
        for closed in usingList{
            if self == closed {
                return true
            }
        }
    
        return false
    }
    
    override var description:String {
        return serialize("")
    }
    
    
    override func clone()->TokenizationState {
        var newState = Branch()
        newState.__copyProperities(self)
        return newState
    }
    
}
