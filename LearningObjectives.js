import React from "react";
import { useState, useEffect } from "react";

export default function LearningObjectives() {
  const [results, setResults] = useState([]);
  useEffect(() => {
    fetch("http://localhost:4000/api/learningObjectives")
      .then((res) => res.json())
      .then((data) => setResults(data)); //fetch takes a whole to execute relative to the rest of the code so square brackets are used to create an empty array
  }, []);
  return (
    //inline css was used here to simplify the file structure and as it is the same for each content component
    <div // body
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: " center",
        backgroundColor: "#b2e4fa",
        height: "calc(100vh - 90px)",
      }}
    >
      <div // frame
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          width: "95%",
          height: "90%",
          backgroundColor: "#d9f2fd",
          borderRadius: "30px",
        }}
      >
        <div // content
          style={{
            display: "flex",
            width: "80%",
          }}
        >
          {/* used the dangerouslySetInnerHTML method to implement the html code pulled from the back end*/}

          {results &&
            results.map(function (result) {
              const markup = { __html: result.learning_objective };
              return <div dangerouslySetInnerHTML={markup} />;
            })}
        </div>
      </div>
    </div>
  );
}
