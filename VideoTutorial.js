import { useState, useEffect } from "react";

export default function Video() {
  const [results, setResults] = useState();

  useEffect(function () {
    // Making an HTTP GET request using Fetch
    fetch("http://localhost:4000/api/VideoTutorial")
      .then((res) => res.json())
      .then((results) => setResults(results));
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
            justifyContent: "center",
          }}
        >
          {results &&
            results.map(function (result) {
              return (
                <div key={result.id}>
                  <iframe /*super easy import from yt Embed feature */
                    width="800"
                    height="480"
                    src={result.video}
                    title="YouTube video player"
                    frameborder="0"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowfullscreen
                  ></iframe>
                </div>
              );
            })}
        </div>
      </div>
    </div>
  );
}
