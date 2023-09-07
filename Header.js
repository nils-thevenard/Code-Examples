import styles from "./Header.module.css";
import React from "react";
import StarLogo from "./Images/StarLogo.png";
import MaoriFlag from "./Images/MaoriFlag.png";
import NZFlag from "./Images/NZFlag.png";

export default function Header() {
  return (
    <div className={styles.Header}>
      {/* div for left side of header */}
      <div className={styles.LH}>
        <img className={styles.StarLogo} src={StarLogo} alt="StarLogo"></img>
        <div className={styles.txt}>
          <div className={styles.txtProject}>PROJECT</div>
          <div className={styles.txtIntroduction}>Introduction</div>
        </div>
        {/*points are simply made from divs and styled in CSS*/}
        <div className={styles.projectCounter}>
          <div className={styles.bigpoint}>1</div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
          <div className={styles.smallpoint}></div>
        </div>
      </div>
      {/* div for right side of header */}
      <div className={styles.RH}>
        <div className={styles.buttons}>
          <button className={styles.takeScreenshot}>Take Screenshot</button>
          <button className={styles.askTeacherForHelp}>
            Ask Teacher For Help
          </button>
          <button className={styles.moreProjects}>More Projects</button>
        </div>
        {/*flags are images imported at the top of the page and referenced here*/}
        <div className={styles.Flags}>
          <img className={styles.NZFlag} src={NZFlag} alt="nz flag"></img>
          <img
            className={styles.MaoriFlag}
            src={MaoriFlag}
            alt="maori flag"
          ></img>
        </div>
      </div>
    </div>
  );
}
