import './App.css';
import WordList from './Components/WordList';
import {Fragment,useState , useEffect ,useContext} from 'react';
import solutionContext from './Components/solutionContext';
const API_URL = 'https://random-word-api.herokuapp.com/word?length=5&number=1000000000'
const ACTIVE = 0 ;
const WON = 1 ;
const LOST = 2 ;
const Modal = (props) => {
  const [modalLife,setModalLife] = useState(true);
  const solution = useContext(solutionContext);
  useEffect(() => {
    if(!modalLife){
      props.operation();
      setModalLife(true);
    }
  },[modalLife])
  return(
    <div className="modal">
      <div className="inner-modal">
        <h1>{props.status==WON?'Congratulations!':'Better Luck Next Time'}</h1>
        <h1>The Word Was {solution}</h1>
        <div className="btn-modal"><button onClick={()=>{setModalLife(false)}}>Restart</button></div>
      </div>
    </div>
  );
}


function App() {
  const [gameState,setGameState] = useState(ACTIVE);
  const [setOfWords,getSetOfWords] = useState(null);
  const [solution,setSolution] = useState(null);
  const [words,setWords] = useState(Array(6).fill(null));
  const [currentWord,setCurrentWord] = useState(()=>'');
  const [currentWordIndex,setCurrentWordIndex] = useState(0);
  const [invalidWord,toggleInvalidWord] = useState(false);
  function restart(){
    setSolution(setOfWords[Math.floor(Math.random()*setOfWords.length)]);
    setGameState(ACTIVE);
    setWords(Array(6).fill(null));
    setCurrentWord('');
    setCurrentWordIndex(0);
    toggleInvalidWord(false);
  }
  const keys = [];
  if(keys.length==0){
      for(let c of "azertyuiopqsdfghjklmwxcvbn"){
          keys.push(<div className="key" key={c} onClick={()=>{
            if(currentWord.length<5){
              setCurrentWord((prev)=>prev+c.toUpperCase());
            }
          }}>
            <button>
              {c.toUpperCase()}
            </button>
          </div>)
      }
  }
  useEffect(()=>{
    async function getWords(){
      const res = await fetch(API_URL);
      const data = await res.json();
      const obtainedSolution = data[Math.floor(Math.random()*data.length)];
      setSolution(obtainedSolution);
      getSetOfWords(data);
    }
    if(!solution){
      getWords();
    }
    console.log(solution);
  },[solution])
  if(solution){
    return (
      <Fragment>
        <solutionContext.Provider value={solution}>
          <WordList words={words} currentWord={currentWord} currentWordIndex={currentWordIndex}  />
          {invalidWord?<div className="warning">Please Insert a valid word</div>:null}
          <div className="keyboard">
          {keys}
          <div className="key" key={'enter'} id="enter" onClick={()=>{
            if(currentWord.length==5){
              setWords(prev=>{
                  let newWords = prev;
                  newWords[currentWordIndex] = currentWord ;
                  return newWords;
                }) ;
                toggleInvalidWord(false);
                setCurrentWordIndex(prev=>prev+1);
                setCurrentWord('');
              if(solution.toUpperCase()==currentWord.toUpperCase()){
                setTimeout(()=>{setGameState(WON);},1100)
                if(invalidWord){
                  toggleInvalidWord(false);
                }
              }
              else if(!setOfWords.includes(currentWord.toLowerCase())){
                toggleInvalidWord(true);
              }
              else if(currentWordIndex==5){
                setTimeout(()=>{setGameState(LOST);},1100);
              }
            }
          }}><button>Enter</button></div>
          <div className="key" key={'back'} id="back" onClick={()=>{
            if(currentWord.length>=0){
              setCurrentWord(prev=>prev.slice(0,prev.length-1));
            }
          }}><button>Back</button></div>
          </div>
          {gameState!=ACTIVE?<Modal status={gameState} operation={restart} />:null}
        </solutionContext.Provider>
      </Fragment>
    );
  }
  else{
    return(
      <div className="loading"><h1>Loading..</h1></div>
    );
  }
}

export default App;
