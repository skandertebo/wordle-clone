import { getQueriesForElement } from "@testing-library/react";
import { useContext } from "react";
import solutionContext from './solutionContext';
const UNFOUND = 0 ;
const FOUND = 1;
const SAMEPOS = 2 ;
const LetterBox = (props) => {
    return (
        <li className="letter-box" key={props.index} style={props.style}>
            {props.letter}
        </li>
    );
}
const Word = (props) => {
    const solution = useContext(solutionContext);
    const letterBoxes = [];
    let letters = [] ;
    for(let index = 0; index < 5; index++) {
        letters.push(solution[index]);
    }
    for(let index=0 ; index < 5 ; index++) {
        let boxStyle = null ;
        if(props.currentWordIndex>props.index){
            let letterState = UNFOUND;
            if(solution[index].toLowerCase()==props.word[index].toLowerCase()){
                letterState = SAMEPOS ;
                const foundLetterIndex = letters.indexOf(props.word[index].toLowerCase());
                letters.splice(foundLetterIndex,1);
            }
            else if(letters.includes(props.word[index].toLowerCase())){
                letterState = FOUND ;
                const foundLetterIndex = letters.indexOf(props.word[index].toLowerCase());
                letters.splice(foundLetterIndex,1);
            }
            boxStyle = {
                animation:props.currentWordIndex == props.index+1?'flip-horizontal-bottom 200ms '+index*200+'ms ease-in-out':'none',
                background:letterState==SAMEPOS?'#79b851':letterState==FOUND?'#f3c237':'#a4aec4',
                color:'white',
                transition:props.currentWordIndex == props.index+1?'background 200ms '+index*200+'ms ease-in-out':'none',
            }
    }
        letterBoxes.push(<LetterBox letter={props.word[index]??''} key={index} index={index} style={boxStyle} />);
    }
    return(
        
        <ul key={props.index}>
            {letterBoxes}
        </ul>      

    );
}
const WordList = (props) => {
        return(

            <div className="word-list">
                {props.words.map((word,index)=>{
                    return(
                        <Word word={index<props.currentWordIndex?word:index==props.currentWordIndex?props.currentWord:''} index={index} key={index} currentWordIndex={props.currentWordIndex} />
                    );
                })}
            </div>
        )
}
export default WordList;