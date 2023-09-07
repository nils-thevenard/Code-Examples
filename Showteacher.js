import Anniesub from "./Anniesub.png"
import styles from "./Showteacher.module.css"
import {FaChalkboardTeacher} from "react-icons/fa"


export default function ShowTeacher(){
    return(
        <div>
            <img className={styles.annieSub} src={Anniesub} alt="annieSub"></img>
            <h3 className={styles.showTeacher}>Show your teacher</h3>
            <p className={styles.paraGraph2}>If your teacher is in the same room as you, click the button below to let them know you are done.</p>
            <a href=" " className={styles.callBtn}>
                <FaChalkboardTeacher className={styles.icon2}/> 
            <br></br>
                Call Teacher
            </a>
        </div>
    )
};
